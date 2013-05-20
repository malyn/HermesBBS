#!/bin/bash


# ######################################################################
# CONFIG VARIABLES
#

# Configure the location of THINK Pascal; default to the Classic Apps
# directory, although this can be overriden with the THINK_PASCAL
# environment variable.
THINK_PASCAL=${THINK_PASCAL:-"/Applications (Mac OS 9)/THINK Pascal 4.0.2"}

# Locate THINK Pascal's RInclude's folder.
RINCLUDES="$THINK_PASCAL/THINK Pascal 4.0 Utilities/Rez Utilities/RIncludes"

# Configure the remaining Mac OS X paths that we need for our script.
PATH=/sbin:/bin:/usr/bin:/Developer/Tools

# Locate the Working directory where we put generated files.
WORKING=Working

# Whether or not we should clobber modified files in the Working
# directory.  Setting this to true (which is available using a command
# line argument) means that the Working directory will be replaced by
# the contents of Source.
SHOULD_CLOBBER=false


# ######################################################################
# SOURCE -> WORKING
#

# Convert Rez files into Mac OS files with a resource fork.
#
# Usage: RezToResource(sourceFile, targetFile, [macosType], [macosCreator])
#   macosType defaults to 'rsrc'
#   macosCreator defaults to 'RSED'
function RezToResource() {
	# Parse the arguments.
	SOURCE=$1
	TARGET=$2
	MACOS_TYPE=${3:-rsrc}
	MACOS_CREATOR=${4:-RSED}

	# Ignore targets that are newer than the source (unless we are
	# clobbering targets).
	if [ -f $TARGET ]; then
		if [ \( ! $SOURCE -nt $TARGET \) -o \( $SHOULD_CLOBBER != true \) ]; then
			echo "$TARGET is up to date"
			return 0
		fi
	fi

	echo "Converting $SOURCE to $TARGET"

	# Create the intermediate file into which we will stage our output.
	# We use an intermediate file so that we do not write a corrupt
	# output file into the target location.
	INT=`mktemp -t hermes_prepare`

	# Convert the Rez file into a Mac OS file with a resource fork; do
	# not overwrite the target if the conversion fails.
	Rez "$RINCLUDES/SysTypes.r" "$RINCLUDES/Types.r" $SOURCE -o $INT -t $MACOS_TYPE -c $MACOS_CREATOR
	if [ $? -eq 0 ]; then
		ditto -rsrcFork $INT $TARGET
		touch -r $SOURCE $TARGET
		rm -f $INT
		return 0
	else
		echo "..failed!"
		rm -f $INT
		return 1
	fi
}

# Convert UTF-8 Unix text files into MacRoman Mac OS text files.
#
# Usage: UnixTextToMacText(sourceFile, targetFile, [macosType], [macosCreator])
#   macosType defaults to 'TEXT'
#   macosCreator defaults to 'PJMM'
function UnixTextToMacText()
{
	# Parse the arguments.
	SOURCE=$1
	TARGET=$2
	MACOS_TYPE=${3:-TEXT}
	MACOS_CREATOR=${4:-PJMM}

	# Ignore already-converted files.
	if [ ! $SOURCE -nt $TARGET ]; then
		echo "$TARGET is up to date"
		return
	fi

	echo "Translating $SOURCE into $TARGET"

	# Create the intermediate file into which we will stage our output.
	# We use an intermediate file so that we do not write a corrupt
	# output file into the target location.
	INT=`mktemp -t hermes_prepare`

	# Convert the file; do not overwrite the target if the conversion
	# fails.
	tr '\n' '\r' < $SOURCE | iconv -f UTF-8 -t MacRoman > $INT
	if [ $? -ne 0 ]; then
		echo "..failed!"
		rm -f $INT
		return 1
	fi

	# The file has been converted; now we need to see if the contents are the
	# same.  If not, then we will only clobber the file if asked to do so.
	# This ensures that we don't accidentally overwriting our working changes.
	if [ -f $TARGET ]; then
		INTMD5=`md5 -q $INT`
		TARGETMD5=`md5 -q $TARGET`
		if [ \( $INTMD5 != $TARGETMD5 \) -a \( $SHOULD_CLOBBER != true \) ]; then
			echo "..refusing to clobber modified working file!"
			rm -f $INT
			return 1
		fi
	fi

	# Copy the file into the target location and set its type and
	# modification date.
	cp $INT $TARGET
	SetFile -t $MACOS_TYPE -c $MACOS_CREATOR $TARGET
	touch -r $SOURCE $TARGET

	# Remove the intermediate file.
	rm -f $INT
}

# Prepares/Updates the Working directory by converting Rez files into
# resource files and Unix text files into Mac OS text files.
function PrepareWorking()
{
	# Create the working directories, just in case this is our first
	# time running the script.
	mkdir -p $WORKING
	mkdir -p $WORKING/Includes
	mkdir -p $WORKING/Source

	# Prepare working files.
	RezToResource Hermes.proj.r $WORKING/Hermes.proj QPRJ PJMM
	RezToResource Hermes.r $WORKING/Hermes.rsrc

	IFS='
	'
	SOURCES=`ls Source/*.p`
	for f in $SOURCES; do
		UnixTextToMacText "$f" "Working/Source/`basename $f`"
	done

	# Prepare includes.
	UnixTextToMacText Includes/HermHeaders.h $WORKING/Includes/HermHeaders.h
}


# ######################################################################
# WORKING -> SOURCE
#

# Convert Mac OS files with a resource fork into Rez files.
#
# Usage: ResourceToRez(sourceFile, targetFile)
function ResourceToRez() {
	# Parse the arguments.
	SOURCE=$1
	TARGET=$2

	# Ignore already-converted files.
	if [ ! $SOURCE -nt $TARGET ]; then
		echo "$TARGET is up to date"
		return
	fi

	echo "Converting $SOURCE to $TARGET"

	# Create the intermediate file into which we will stage our output.
	# We use an intermediate file so that we do not write a corrupt
	# output file into the target location.
	INT=`mktemp -t hermes_prepare`

	# Convert the Mac OS file into a Rez file; do not overwrite the
	# target if the conversion fails.
	DeRez $SOURCE "$RINCLUDES/SysTypes.r" "$RINCLUDES/Types.r" > $INT
	if [ $? -eq 0 ]; then
		cp $INT $TARGET
		touch -r $SOURCE $TARGET
		rm -f $INT
		return 0
	else
		echo "..failed!"
		rm -f $INT
		return 1
	fi
}

# Convert MacRoman Mac OS text files into UTF-8 Unix text files.
#
# Usage: UnixTextToMacText(sourceFile, targetFile)
function MacTextToUnixText()
{
	SOURCE=$1
	TARGET=$2

	# Ignore already-converted files.
	if [ ! $SOURCE -nt $TARGET ]; then
		echo "$TARGET is up to date"
		return
	fi

	echo "Translating $SOURCE into $TARGET"

	INT=`mktemp -t hermes_prepare`

	# Convert the file; do not overwrite the target if the conversion
	# fails.
	tr '\r' '\n' < $SOURCE | iconv -f MacRoman -t UTF-8 > $INT
	if [ $? -ne 0 ]; then
		echo "..failed!"
		rm -f $INT
		return 1
	fi

	# Copy the file into the target location and set its type and
	# modification date.
	cp $INT $TARGET
	touch -r $SOURCE $TARGET

	# Remove the intermediate file.
	rm -f $INT
}

# Prepares/Updates the Source directory by converting resource files
# into Rez files and Mac OS text files into Unix text files.
function PrepareSource()
{
	# Prepare BBS source files.
	ResourceToRez $WORKING/Hermes.proj Hermes.proj.r
	ResourceToRez $WORKING/Hermes.rsrc Hermes.r

	IFS='
	'
	WORKING_SOURCES=`ls $WORKING/Source/*.p`
	for f in $WORKING_SOURCES; do
		MacTextToUnixText "$f" "Source/`basename $f`"
	done

	# Prepare includes.
	MacTextToUnixText $WORKING/Includes/HermHeaders.h Includes/HermHeaders.h
}


# ######################################################################
# MAIN ENTRY POINT
#

# Prepare source or working according to the command line arguments.
if [ "x$1" == "xworking" ]; then
	PrepareWorking
elif [ "x$1" == "xclobberworking" ]; then
	SHOULD_CLOBBER=true
	PrepareWorking
elif [ "x$1" == "xsource" ]; then
	PrepareSource
else
	echo "usage: prepare.sh working|clobberworking|source"
	echo
	echo "  working: convert source files into working files."
	echo
	echo "  clobberworking: convert source files into working files,"
	echo "      clobbering any working modifications."
	echo
	echo "  source: convert working files back into source files."
	exit 1
fi

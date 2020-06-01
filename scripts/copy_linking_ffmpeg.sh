#determine the last local ffmpeg version
COPY_FROM_PATH=""
for ffmpeg_path in `brew info ffmpeg | grep 'Cellar/ffmpeg/.*\*' | awk -F' ' '{ print $1 }'`; do COPY_FROM_PATH="$(echo $ffmpeg_path)"; done;

cp -v -f $COPY_FROM_PATH/bin/ffmpeg ./mac

#replace references to an absolute path with @loader_path
#which will allow to run ffmpeg that loads dylibs from the bundle
function replace_dlybs() {
	DYLIBS=`otool -L $1 | grep "/usr/local/Cellar" | awk -F' ' '{print \$1 }'`
	for dylib in $DYLIBS; do sudo install_name_tool -change $dylib @loader_path/`basename $dylib` $1; done;
	for dylib in $DYLIBS; do cp -f -n $dylib ./mac; done;
	DYLIBS=`otool -L $1 | grep "/usr/local/opt" | awk -F' ' '{print \$1 }'`
	for dylib in $DYLIBS; do sudo install_name_tool -change $dylib @loader_path/`basename $dylib` $1; done;
	for dylib in $DYLIBS; do cp -f -n $dylib ./mac; done;

	sudo install_name_tool -id @loader_path/`basename $dylib` $1
}

#first replace occurences in ffmpeg
replace_dlybs "./mac/ffmpeg"

#then replace occurrences in all the additional dylibs that were copied in the previous step
for file in `ls mac/*.dylib`; do
	echo replacing dylibs for $file
	replace_dlybs $file
done;

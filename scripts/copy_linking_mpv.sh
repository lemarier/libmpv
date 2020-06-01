#determine the last local ffmpeg version
COPY_FROM_PATH=""
for ffmpeg_path in `brew info mpv | grep 'Cellar/mpv/.*\*' | awk -F' ' '{ print $1 }'`; do COPY_FROM_PATH="$(echo $ffmpeg_path)"; done;

# get mpv lib
for source in `find $COPY_FROM_PATH/lib -type f | grep libmpv`; do cp -v -f $source ./mac; done;


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

#first replace occurences in ffmpeg and ffprobe binaries
for file in `ls mac/*`; do
	echo replacing dylibs for $file
	replace_dlybs $file
done;

# missing deps
cp -R /usr/local/opt/libffi/lib/libffi.7.dylib ./mac/

#then replace occurrences in all the additional dylibs that were copied in the previous step
for file in `ls mac/*.dylib`; do
	echo replacing dylibs for $file
	replace_dlybs $file
done;

#rm -Rf mac/Python
rm -Rf mac/libmpv.1.dylib
ln -s ./libmpv.1.107.0.dylib ./mac/libmpv.1.dylib
ln -s ./libmpv.1.107.0.dylib ./mac/libmpv.dylib
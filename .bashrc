for file in $(find ~/.bashrc.*) ; do
	if [ -f "$file" ] ; then
		echo Sourcing $file
		source $file
	fi
done

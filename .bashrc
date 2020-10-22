for file in $(ls -a | egrep '.+.bashrc') ; do
	if [ -f "$file" ] ; then
		echo Sourcing $file
		source $file
	fi
done

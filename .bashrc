for file in $(ls -a $HOME | egrep '.+.bashrc') ; do
	echo Sourcing $file
	source ~/$file
done

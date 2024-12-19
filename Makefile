build:
	bash zanominer.sh install

rebuild:
	zanominer uninstall
	bash zanominer.sh install
	
delete:
	zanominer uninstall
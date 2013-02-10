iconforfile
===============
Basically a command line version of <https://github.com/socketwiz/IconForFileType>.  I also needed an icon for a file but wanted it from another process that couldn't easilly make cocoa calls.  

Usage
-----
	Usage iconforfile [OPTIONS] <arguments separated by space>
	-f --file <value>   icon by file, complete path 
	-t --type <value>   icon by type (i.e. file extension) 
	-o --output <value> output file, Write output to file.  Default is stdout 
	-s --size <value>   pixel size. Default is 16 
	-b --base64         output in base64 
	-v --printVersion   Display version and exit 
	-h --printHelp      Display this help and exit 
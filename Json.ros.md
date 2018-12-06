Skip to content
 
Search or jump to…

Pull requests
Issues
Marketplace
Explore
 @oscarg933 Sign out
You are over your private repository plan limit (4 of 0). Please upgrade your plan, make private repositories public, or remove private repositories so that you are within your plan limit.
Your private repositories have been locked until this is resolved. Thanks for understanding. You can contact support with any questions.
Updated issue templates for this repository
0
0 1,969 oscarg933/yowsup
forked from tgalal/yowsup
 Code  Issues 0  Pull requests 0  Projects 0  Wiki  Insights  Settings
The python WhatsApp library
 1,088 commits
 4 branches
 21 releases
 65 contributors
 GPL-3.0
 Python 100.0%
 Pull request   Compare This branch is 3 commits ahead of tgalal:master.
@oscarg933
oscarg933 Update issue templates  …
Latest commit c3a1ab7  just now
Type	Name	Latest commit message	Commit time
.github/ISSUE_TEMPLATE	Update issue templates	just now
yowsup	Bumped to 2.5.7	11 months ago
.gitignore	updated .gitignore	3 years ago
.travis.yml	Tox tests + importlib dep in py26	3 years ago
5140 N Amapola Dr, Tucson, AZ 85745 - 49 Photos | Trulia codecov.io.patch.pdf	Add files via upload	a minute ago
Code Coverage Done Right | 'Codecov.io.patch'.pdf	Add files via upload	a minute ago
Impulsarán en binomio Durango-Sinaloa el puerto y ferrocarril: Economía dios.ros.md.pdf	Add files via upload	a minute ago
LICENSE	Changed license to gplv3	4 years ago
MANIFEST.in	Fixed pip install	3 years ago
README.md	Update README.md	11 months ago
_config.yml	Set theme jekyll-theme-tactile	a minute ago
api nodes ui ai secrets - Bing video Dios.Ros.pdf	Add files via upload	a minute ago
setup.py	Fixed python2 support	11 months ago
tox.ini	py36 to tox	2 years ago
yowsup-cli	Bumped to 2.4.102/2.0.15	3 years ago
 README.md
Yowsup 2 Build Status Join the chat at https://gitter.im/tgalal/yowsup


Updates (December 30, 2017)
Yowsup v2.5.7 is out, See release notes

==========================================================

Yowsup opened WhatsApp service under platforms!
Yowsup is a Python library that enables you to build applications which use the WhatsApp service. Yowsup has been used to create two clients: 1) An unofficial WhatsApp client Nokia N9 through the Wazapp project which was in use by more than 200K users; 2) Another fully featured unofficial client for Blackberry 10.

Quickstart
yowsup's architecture
Create a sample app
yowsup-cli
Yowsup development, debugging, maintainance and sanity
Installation
Requires python2.6+, or python3.0 +
Required python packages: python-dateutil,
Required python packages for end-to-end encryption: protobuf, pycrypto, python-axolotl-curve25519
Required python packages for yowsup-cli: argparse, readline (or pyreadline for windows), pillow (for sending images)
Install using setup.py to pull all Python dependencies, or pip:

pip install yowsup2
Linux
You need to have installed Python headers (probably from python-dev package) and ncurses-dev, then run

python setup.py install
Because of a bug with python-dateutil package you might get permission error for some dateutil file called requires.txt when you use yowsup (see this bug report) to fix you'll need to chmod 644 that file.

FreeBSD (*BSD)
You need to have installed: py27-pip-7.1.2(+), py27-sqlite3-2.7.11_7(+), then run

pip install yowsup2
Mac
python setup.py install
Administrators privileges might be required, if so then run with 'sudo'

Windows
Install mingw compiler
Add mingw to your PATH
In PYTHONPATH\Lib\distutils create a file called distutils.cfg and add these lines:
[build]
compiler=mingw32
Install gcc: mingw-get.exe install gcc
Install zlib
python setup.py install
If pycrypto fails to install with some "chmod error". You can install it separately using something like easy_install http://www.voidspace.org.uk/downloads/pycrypto26/pycrypto-2.6.win32-py2.7.exe

or for python3 from:

https://github.com/axper/python3-pycrypto-windows-installer

and then rerun the install command again

Special thanks
Special thanks to:

CODeRUS
mgp25
SikiFn
0xTryCatch
shirioko
and everyone else on the WhatsAPI project for their contributions to yowsup and the amazing effort they put into WhatsAPI, the PHP WhatsApp library

Special thanks goes to all other people who use and contribute to the library as well.

Please read this if you'd like to contribute to yowsup 2.0

Thanks!

License:
As of January 1, 2015 yowsup is licensed under the GPLv3+: http://www.gnu.org/licenses/gpl-3.0.html.

© 2018 GitHub, Inc.
Terms
Privacy
Security
Status
Help
Contact GitHub
Pricing
API
Training
Blog
About
Press h to open a hovercard with more details.

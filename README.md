# AdobeGenp
AdobeGenp Adobe Adobe CC 2019/2020/2021/2022(test)/2023(test)/2024(test) GenP Universal Patch 2024 - Software  from  cybermania 

Thanks to MIkeVirtual / E1uSiv3 sharing If V3.4.14.1 not work,Please try V3.3.10


    Last V 3.4.1&3.4.14.1
    https://www.mediafire.com/file/pad3qpnmncwaqeb/Adobe-GenP-3.3.10-CGP.7z/file
    https://www.mediafire.com/file/4cu6f1cpy7ozx3a/Adobe_GenP_3.4.14.1.7z/file



Adobe universal patch. Can patch 2019/2020/2021 adobe product.


How to use GenP:

If you want to patch all Adobe apps in default location:
Press ‘Search Files’ – wait until GenP finds all files.
Press ‘Pill Button’ – wait until GenP do it’s job.
One Adobe app at a time:
Press ‘Custom path’ – select folder that you want [depending upon the app you want to patch]
Press ‘Search Files’ – wait until GenP finds all files.
Press ‘Pill Button’ – wait until GenP do it’s job.




 
GenP CGP Community Edition v3.4.1

Release Notes:
– Fixed “Unable to allocate memory” error when patching large binaries

– Improved fixes for crashes during app startup
– Added Premiere Pro 24.6.1/25 Beta blank home screen fix
– Added MD5 checksum output for each patched file in log — potentially helpful when troubleshooting [enable/disable in Options tab or config.ini]

 

homescreen fix is same as Photoshop patches… just had to add config.ini output to include file path for premiere as it’s slightly different vs photoshop.

3.3.12 patches fixed crashes for signed OUT users but had issues with users signed IN with expired trial (no issues for signed users who did not start trial).. but 3.4.0 fixes all that.







GenP 3.4.14.1 ReleaseFull changelog:

Fixed the issue where people with corrupted Windows installations could not use RunAsTI/NSudo.
GenP will now ask if you want to run as a Trusted Installer on startup.
If you see GenP crash on startup or your mouse cursor spins endlessly
Press “no” on this popup after closing GenP in Task Manager.

Added support for Audition (Beta).
(PS: Previous versions of GenP damaged Audition Beta’s files
Reinstall it before trying to patch it again.)

Added support for Character Animator (Beta).

Packed NSudo and the config.ini files within the executable itself
As a result, GenP is now one single executable
(Which works without extracting the files, we still recommend you extract it, though)

Fixed the issue where people’s hosts files would get overwritten at times.

Added support for x86 installations of Creative Cloud, so you don’t have to manually pick the path

Removed support for Cinema 4D as the version bundled with After Effects is no longer supported

Improved scanning speed.

Improved PowerShell code for systems that are badly configured
or have corrupted environment variables.

Fixed weird C:\Windows\System32\config\systemprofile error
(When the CC files are not found when patching CC).

Fixed typo (grammatical errors) in ARM detection code.

General stability/code fixes.

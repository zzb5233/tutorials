# Introduction

Known minor issues that anyone who knows how to fix is welcome to
suggest improvements:

+ The desktop icon for the Wireshark application does not seem to
  exist, at least not under the name that worked for Ubuntu 20.04, so
  it shows up as a question mark.


# Creating the VM

+ Below are the steps to create a brand new VM using Vagrant:
  + Install [Vagrant](https://developer.hashicorp.com/vagrant/docs/installation) on your system if it's not already installed.
  + In a shell/terminal window, change to this `vm-ubuntu-24.04`
    directory inside the `tutorials` directory.
  + Run the below command in the terminal.
    
    ```bash
    vagrant up dev
    ```

  - This command will initiate the creation of a development VM.
  - The VM will include P4 software installed built from source code.

+ `vagrant up` is not supported, as there are not currently
  pre-compiled Ubuntu 24.04 packages being created by anyone.

*Note* that creating a development VM can take several hours,
depending upon the speed of your computer and Internet connection.


## GUI settings that you will likely wish to change

+ Log in as user p4 (password p4)
+ Start menu -> Preferences -> LXQt settings -> Monitor settings
  + Change resolution from initial 800x600 to 1024x768.  Apply the changes.
  + Close monitor settings window
  + *Note*: For some reason I do not know, these settings seem to be
    undone after a reboot, even if I use the "Save" button.  Still,
	you might like to redo this setting each time you boot the system,
	if the screen resolution is too limiting.
+ Start menu -> Preferences -> LXQt settings -> Appearance
  + Click "Icons Theme" in left column
  + Click "Ubuntu-Mono-Light ..." in right column.
  + Click "Apply" button, then "Close" button.
+ Several of the icons on the desktop have an exclamation mark on
  them.  If you try double-clicking those icons, it pops up a window
  saying "This file 'Wireshark' seems to be a desktop entry.  What do
  you want to do with it?" with buttons for "Open", "Execute", and
  "Cancel".  Clicking "Execute" executes the associated command.
  If you do a mouse middle click on one of these desktop icons, a
  popup menu appears where the second-to-bottom choice is "Trust this
  executable".  Selecting that causes the exclamation mark to go away,
  and future double-clicks of the icon execute the program without
  first popping up a window to choose between Open/Execute/Cancel.  I
  did that for each of these desktop icons:
  + Terminal
  + Wireshark
+ (optional, if you want a desktop with the P4 logo) Start menu ->
  Preferences -> LXQt settings -> Desktop
  + Click "Background" tab
  + To the right of "Wallpaper image file" name, click "Browse"
    button.  Find and choose "lxqt-default-wallpaper.png" from the
    list and click "Open".
  + In "Wallpaper mode" popup menu, choose "Center on the screen".
  + Click Apply button
  + Close "Desktop preferences" window
+ Log off

+ Log in as user vagrant (password vagrant)
+ Change monitor settings and wallpaper mode as described above for
  user p4.
+ Open a terminal.
  + Run the command
    
    ```bash
    ./clean.sh
    ```
    which removes several GigaBytes of files created while building
    the projects.
+ Log off

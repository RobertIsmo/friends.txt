# Friends.txt

**Friends.txt** is a standard way to communicate over the web who you like, and who they like too! Friends.txt is based around a file you serve on your website of the same name. Here is my [/friends.txt](https://robertismo.com/friends.txt)! It is really simple. You can then go to the source code and use the `friends` app to automatically generate a friends page, that you then statically serve on your page. Here is my [friends page](https://robertismo.com/friends). It will pull your friends, and also the friends of your friends to help others discovery really cool pages in your friend network.

## Installation

To install to your user at ~/.local/bin

```curl -sSL https://robertismo.com/releases/friends.txt/install.sh | sh```

To install system-wide at /usr/local/bin

```curl -sSL https://robertismo.com/releases/friends.txt/install.sh | sudo sh```

Binaries are also available at [https://robertismo.com/releases/friends.txt](https://robertismo.com/releases/friends.txt).

### Windows

There is no release for the Windows operating system, you can learn to switch from Windows to Linux [here](https://www.youtube.com/results?search_query=switch+from+windows+to+linux) and at a variety of other resources.

## Usage

Currently this app expects there to be a `www` folder, which is the index of your webpage. place in there a `friends.txt`. for example.

```txt
example.com
robertismo.com
agencyeconomy.org
```

with a newline seperated list of your friend's domains. then run `friends`. It will generate a `www/friends/index.html`, if you serve your `www` folder, you can access this at `/friends`. 

### Styling

`www/friends/index.html` will link a `/friend.css` file if you want to style the page.



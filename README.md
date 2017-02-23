## Top words parser
Completely useless utility that takes headlines from **hckrnews** and output the most frequently encountered words. Could be used for hype detecting.


### Installation
`GHC` and `cabal` are required to build it. Installation in sandbox:

```
cd hntopwords
cabal sandbox init
cabal install
```
Once utility was build you can find it in the sandbox building directory:
`./dist/dist-sandbox-<somenum>/build/hckrnewsparser/hckrnewsparser`


### Usage
In order to use utility you need at least a text file containing words that must be excluded from the output. Example of such a file is `filter_words.txt`. File could be empty if you want to process all the words.

```
hckrnewsparser -w 200 -f filter_words.txt
```

Option `-w` set number of top words to show, default is 100.

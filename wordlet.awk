#!/usr/bin/env -S awk -v dict=/usr/share/dict/words -v moved_color=3 -f
# Wordlet, a word game written in AWK and playable from the command line!

function mistake(msg) {
    print "\x1b[1A\x1b[90m\x1b[9m" $0 "\x1b[0m\x1b[" (termcols - 1 - length(msg)) "G: \x1b[3m" msg "\x1b[0m"
}

function keyboard() {
    printf "\x1b[" (tries + 2) "A"
    printf " "
    for (i = 65; i < 91; i++) {
        printf "\x1b[30m[\x1b[0m"
        _c = sprintf("%c", i)
        if (guessed_exact[_c]) {
            printf exact_color "\x1b[30m"
        } else if (guessed_moved[_c]) {
            printf moved_color "\x1b[30m"
        } else if (guessed_miss[_c]) {
            printf "\x1b[30m\x1b[100m\x1b[9m"
        }
        printf("%s\x1b[0m", _c, i)
        printf "\x1b[30m]\x1b[0m"
    }
    printf "\n"
    printf "\x1b[" (tries + 2) "B"
}

BEGIN {
    if (termcols == "")
        termcols = 80

    if (wordlen == "")
        wordlen = 5

    if (maxtries == "")
        maxtries = 6

    if (exact_color == "")
        exact_color = 2
    exact_color = "\x1b[4" exact_color "m"

    if (moved_color == "")
        moved_color = 5
    moved_color = "\x1b[4" moved_color "m"

    if (dict == "") {
        print "Usage: awk -v dict=/path/to/words [-v wordlen=N] [-v maxtries=N] -f wordlet.awk"
        exit 1
    }

    printf "\x1b[90m"

    print "Indexing the dictionary, please wait..."

    while (("dd if=" dict " status=progress"  \
            " |grep -E ^.{" wordlen "}$ "     \
            " |tr [:lower:] [:upper:]"        \
            " |sed -e 's/./& /g' -e 's/ $//'" \
            " |sort -R" | getline result) > 0) {
        words[length(words) + 1] = result
        words[result] = 1
    }
    split(words[1], word)

    printf "\x1b[0m"

    if (length(words) <= 1) {
        print "The dictionary has no " wordlen "-letter words!"
        exit 1
    }

    print "\x1b[1m"
    print "==================="
    print "Welcome to Wordlet!"
    print "==================="
    print "\x1b[0m"
    print "The objective of this game is to guess a \x1b[1m" wordlen "-letter\x1b[0m word in \x1b[1m" maxtries " tries\x1b[0m."
    print "Press \x1b[31m^D\x1b[39m (\x1b[31mCtrl-d\x1b[39m) to give up \x1b[3m(don't)\x1b[0m.\n\n\n"

    keyboard()
}

{
    tries++
}

NF == 1 {
    split($0, guess, "")
    for (i = 1; i <= length(guess); i++) {
        $i = guess[i]
    }
}

{
    for (i = 1; i <= NF; i++) {
        $i = toupper($i)
    }
}

NF != wordlen {
    NR--
    msg = "the word must be " wordlen " letters in length, not " NF "!"
    mistake(msg)
    keyboard()
    next
}

$0 in words == 0 {
    NR--
    msg = "not a word!"
    mistake(msg)
    keyboard()
    next
}

$0 in words {
    printf "\x1b[1A"

    delete matches
    for (i = 1; i <= NF; i++)
        if ($i != word[i])
            matches[word[i]]++

    for (i = 1; i <= NF; i++) {
        if ($i == word[i]) {
            printf exact_color "\x1b[30m"
            guessed_exact[$i]++
        } else if (matches[$i] > 0) {
            printf moved_color "\x1b[30m"
            matches[$i]--
            guessed_moved[$i]++
        } else {
            guessed_miss[$i]++
        }
        printf $i "\x1b[0m "
    }
    print ""

    keyboard()
}

$0 == words[1] {
    print "\nYou guessed the word in " NR " tries!"
    exit 0
}

NR == maxtries {
    print "\nSorry, maybe next time..."
    exit 0
}

END {
    if (words[1])
        print "The word was: \x1b[1m" words[1] "\x1b[0m"
}

# BSD Zero Clause License
#
# Copyright (c) 2022 Jeremiasz Nelz
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# vim: set ts=4 sw=4 sts=4 et :

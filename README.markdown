# imap2atom 

`imap2atom` provides a means to serialize an IMAP inbox as an Atom document.
The resultant Atom feed can then be published and subscribed to or plugged
into a query system such as [YQL](http://developer.yahoo.com/yql).

## Getting Started

Install the `builder` dependency:

    $ sudo gem install builder

## Use

List available mailboxes:

    $ ./imap2atom.rb --list imap://user:password@mail.example.com/

Dumping an INBOX (defaulting to 20 items), using "Me" as the feed title:

    $ ./imap2atom.rb --title Me imap://user:password@mail.example.com/INBOX

Dumping the last 5 items in my inbox:

    $ ./imap2atom.rb -n 5 imap://user:password@mail.example.com/INBOX

Dumping a Google Apps account:

    $ ./imap2atom.rb --gmail imap://user:password@example.org/INBOX

This is the equivalent of:

    $ ./imap2atom.rb -p 993 --ssl imap://user%40example.org:password@imap.gmail.com/INBOX

---

Copyright (c) 2009 Seth Fitzsimmons, released under the MIT license
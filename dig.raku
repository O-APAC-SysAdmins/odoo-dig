#!/usr/bin/env raku

use Air::Functional :BASE;
use Air::Base;
use Air::Component;

class Dig does Component {
    has $!response;
    
    method search(:$request) is controller {
        return '' unless $request;

        my $dig-proc = run <dig MX>, $request, :out;
        my $dig-out  = $dig-proc.out.slurp;
        my $output   = $dig-out ~~ / ';; ANSWER SECTION:' \n (.*?) \n\n / ?? ~$0.trim !! "No MX record found.";
        say $output.raku;
        $!response = $output;
        self;
    }
    
    method hx-search(--> Hash()) {
        :hx-get("$.url-path/search"),
        :hx-target("#search-result"),
        :hx-swap<innerHTML>,
        :hx-trigger<submit>,
    }
    
    method HTML {
        pre [ code "$!response" ]
    }
}

my Dig $dig .= new;
my &index    = &page.assuming(
                   title => "Dig DB Lookup",
               );

sub SITE {
    site :register[$dig], :data-theme<purple>,
    index
        main :class<container>, [
        article [
            h3 "DB Lookup !";
            form |$dig.hx-search, [
                input :name<request>, :placeholder("random.db.odoo.com");
                button :type<submit>, 'Search!';
            ];
            div :id("search-result");
        ]
    ];
}

SITE.serve;

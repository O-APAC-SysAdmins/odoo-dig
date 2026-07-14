#!/usr/bin/env raku

use Air::Functional :BASE;
use Air::Base;
use Air::Component;

class Dig does Component {
    has $!response;
    has @!details;
    
    method search(:$request) is controller {
        return '' unless $request;

	# clean request
	my $domain = $request;
	if $request.contains(/ <[ : ? # - ]> /) {
	    $domain = $request.comb(/ <-[ / : ? # ]>+ /).max(*.chars);
	    say $domain.raku;
	    @!details.push: "cleaned to: $domain";
	}
	if ! $domain.ends-with('odoo.com') {
	    $domain .= subst('.');
	    $domain ~= '.odoo.com';
	    say $domain.raku;
	    @!details.push: "appeneded .odoo.com";
	}
	
	# get MX records if any
        my $dig-proc = run <dig MX>, $domain, :out;
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
	LEAVE @!details = ();
	div [
            pre [ code "$!response" ];
	    pre [ code :style<color: red;>, @!details.join("\n")  ] if @!details;
	]
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

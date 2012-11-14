What?
=====

An experiment to see how Puppet would be without any
branches, language, boolean logic, variables or scope,
or weird ordering.

Achieve this by expressing classes and resources in
YAML files.  Everything is managed by hiera which means
every property of every resource and class can be manipulated
by the hierarchy of data.

Main features to consider are:

  * Everything is YAML - but normal Puppet classes are usable
  * No branching, variables or logic, hierarchy based overrides instead
  * Everything including every property of every resource can be managed by hiera
  * Resources are added in a top down manner

**NOTE::** This is at best an exploration of the idea and
not intended for every day use.  The code was written on
a plane mostly around 2am so it's pretty grim, but it's
functional and a good way to explore how such a thing would
feel

Why?
----

This is not ment as a replacement for the Puppet DSL,
in fact you can use any existing Puppet Classes or Defines
from this DSL - though you cannot do the overrides on those
resources not created in the DSL.

I wanted to explore the possiblity of creating an entirely
new experience ontop of the Puppet catalog, resources, providers
etc that relies heavily on convention and not on any programming

As the input is all data this creates many oppertunities
like creating UIs that generate this data dynamically, consider
this an ENC on steriods.  You can create resources and classes
at will with relationships between those classes.

I can imagine versioned classes, or classes that require signoff
before release to the estate or general workflows, simply because
all you need is a database and something to provide the data to
hiera, how you get there is up to you.

Example?
--------

First we start with a class, this is just *classes/common.yaml*:

    resources:
      - notify:
        - starting

      - file:
        - /tmp/foo:
            content: hello

        - /tmp/bar:
            content: bar

      - notify:
        - ending:
            notify: Class[x]

      - class:
        - x

This class has a bunch of resources in it - it also includes
another class *x* from normal puppet manifests.

The resources will be added in a way that means they get applied
to the node top down in the order they appear here.

Now lets see how the hierarchy build up the resources and nodes:

Given a hiera config:

    :backends:
      - yaml

    :hierarchy:
      - "%{::fqdn}"
      - common

You can see we have a common and fqdn tier, lets look at the common
tier:

    classes:
      - common -> apache

It says it wants to include 2 classes *common* and *apache* but it
also sets some ordering, the apache class will depend on the common
class.  Without ordering it would just be an array with 2 items, 1
per class.

Now lets look at the node specific YAML file:

    classes:
      - apache -> webapp

    notify::starting:
      message: start overriden

    notify::ending:
      message: ending overriden

    x::y: hello

Here we add a 3rd class called webapp which should depend on the
apache class.

We override the *message* property of the *Notify[starting]* and
*Notify[ending]* resources that were defined in the common class
earlier.

And finally we supply the *y* parameter to the parameterized class *x*

Output?
-------

There is a fully worked example in *hieradata* and *puppet_test.pp*
which produce the following output:

    common_start_anchor
    /Stage[main]/Common/Notify[common_start_anchor]/message: defined 'message' as 'common_start_anchor'
    start overriden
    /Stage[main]/Common/Notify[starting]/message: defined 'message' as 'start overriden'
    ending overriden
    /Stage[main]/Common/Notify[ending]/message: defined 'message' as 'ending overriden'
    /Stage[main]/X/Exec[/bin/echo 'inside x y is hello']: Triggered 'refresh' from 1 events
    common_end_anchor
    /Stage[main]/Common/Notify[common_end_anchor]/message: defined 'message' as 'common_end_anchor'
    apache_start_anchor
    /Stage[main]/Apache/Notify[apache_start_anchor]/message: defined 'message' as 'apache_start_anchor'
    apache_end_anchor
    /Stage[main]/Apache/Notify[apache_end_anchor]/message: defined 'message' as 'apache_end_anchor'
    foo_start_anchor
    /Stage[main]/Foo/Notify[foo_start_anchor]/message: defined 'message' as 'foo_start_anchor'
    foo_end_anchor
    /Stage[main]/Foo/Notify[foo_end_anchor]/message: defined 'message' as 'foo_end_anchor'
    Finished catalog run in 0.14 seconds

Note I use a notify as an anchor, this is basically a TODO to use the
anchor resources from stdlib but did not have it with me one the plane

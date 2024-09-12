#!/usr/local/bin/perl
use strict;
use warnings;
use lib '/server/perl';
use REGEX;

my $SIMPLE_LOG_FILE="$ARGV[0]";
my $CURRENT_USERS_FILE="$ARGV[1]";
my $LOG_DATE_FORMAT="+%FT%H:%M:%S";
my $REGEX_SEVER_START=REGEX->Arguments('--find', "Took ([0-9\\.]+) seconds to LoadMap.*/Game/FactoryGame/Map/DedicatedserverEntry", '--group', 1, '--iterator', '--trim');
my $REGEX_SESSION_START=REGEX->Arguments('--find', "Took ([0-9\\.]+) seconds to LoadMap.*/Game/FactoryGame/Map/GameLevel01/Persistent_Level", '--group', 1, '--iterator', '--trim');
my $REGEX_PLAYER_LOGIN_ID=REGEX->Arguments('--find', "Login request:.*Name=(.+)\\s+userId:\\s+([^)]+\\))", '--group', 2, '--iterator', '--trim');
my $REGEX_PLAYER_LOGIN_NAME=REGEX->Arguments('--find', "Login request:.*Name=(.+)\\s+userId:\\s+([^)]+\\))", '--group', 1, '--iterator', '--trim');
my $REGEX_PLAYER_JOIN_ID=REGEX->Arguments('--find', "Join request:.*ClientIdentity=([^?]+).*Name=([^?]+)", '--group', 1, '--iterator', '--trim');
my $REGEX_PLAYER_JOIN_NAME=REGEX->Arguments('--find', "Join request:.*ClientIdentity=([^?]+).*Name=([^?]+)", '--group', 2, '--iterator', '--trim');
my $REGEX_PLAYER_JOINED_NAME=REGEX->Arguments('--find', "Join succeeded:\\s+(.+)", '--group', 1, '--iterator', '--trim');
my $REGEX_PLAYER_LEAVE_ID=REGEX->Arguments('--find', "UNetConnection::Close.*Driver:\\s+GameNetDriver.*UniqueId:\\s+([^,]+),", '--group', 1, '--iterator', '--trim');


open(SIMPLE, '>>', $SIMPLE_LOG_FILE) or die("Unable to open ${SIMPLE_LOG_FILE}");
open(USERS, '>', $CURRENT_USERS_FILE) or die("Unable to open ${CURRENT_USERS_FILE}");
close(SIMPLE);
close(USERS);

sub simpleLog($) {
    my ($line) = @_;
    my $date = `date $LOG_DATE_FORMAT`;
    chomp($date);
    open(SIMPLE, '>>', $SIMPLE_LOG_FILE) or die("Unable to open ${SIMPLE_LOG_FILE}");
    print SIMPLE '[' . $date . '] ' . $line . "\n";
    close(SIMPLE);
}

sub addUser($$) {
    my ($id,$name) = @_;
    removeUser($id);

    open(ADD_USER, '>>', $CURRENT_USERS_FILE);
    print ADD_USER "'${id}' '${name}'\n";
    close(ADD_USER);
}

sub activeUser {
    my $usersIterator = REGEX->Arguments('--find', "'\\s+'(.*)'\$", '--group', 1, '--file', $CURRENT_USERS_FILE, '--iterator')->Process();
    my $users = '';
    while (my $user = $usersIterator->()) {
        chomp($user);
        $users.=" ${user}";
    }
    return substr($users, 1);
}

sub getUser($) {
    my ($id) = @_;
    $id =~ s/(.)/[$1]/g;
    $id =~ s/(\[\s\])/\\s/g;
    $id =~ s/(\[\]\])/\[\\\]\]/g;
    return REGEX->Arguments('--find', "^'${id}'\\s+'(.*)'\$", '--group', 1, '--file', $CURRENT_USERS_FILE, '--iterator', '--trim')->Process()->();
}

sub removeUser($) {
    my ($id) = @_;
    $id =~ s/(.)/[$1]/g;
    $id =~ s/(\[\s\])/\\s/g;
    $id =~ s/(\[\]\])/\[\\\]\]/g;
    my $usersIterator = REGEX->Arguments('--find', "^'${id}'\\s+'(.*)'\$", '--delete', '--file', $CURRENT_USERS_FILE, '--iterator')->Process();
    my @users = ();
    while (my $user = $usersIterator->()) {
        chomp($user);
        push(@users, $user);
    }
    open(UPDATE_USER, '>', $CURRENT_USERS_FILE);
    foreach my $user (@users) {
        print UPDATE_USER "$user\n";
    }
    close(UPDATE_USER);
}

sub processLine($) {
    my ($line) = @_;
    my $id='';
    my $name='';
    my $time='';

    $time=$REGEX_SEVER_START->Process($line)->();
    if ($time) {
        simpleLog("Server Started in ${time}s");
    }

    $time=$REGEX_SESSION_START->Process($line)->();
    if ($time) {
        simpleLog("Session Started in ${time}s");
    }

    $id=$REGEX_PLAYER_LOGIN_ID->Process($line)->();
    if ($id) {
        my $name=$REGEX_PLAYER_LOGIN_NAME->Process($line)->();
        simpleLog("Player Connected (${name})");
        addUser($id, $name);
    }

    $id=$REGEX_PLAYER_JOIN_ID->Process($line)->();
    if ($id) {
        my $name=$REGEX_PLAYER_JOIN_NAME->Process($line)->();
        simpleLog("Player Joining (${name})");
        addUser($id, $name);
    }

    $name=$REGEX_PLAYER_JOINED_NAME->Process($line)->();
    if ($name) {
        simpleLog("Player Joined (${name})");
    }

    $id=$REGEX_PLAYER_LEAVE_ID->Process($line)->();
    if ($id) {
        my $name = getUser($id);
        if ($name) {
            simpleLog("Player Left (${name})");
        } else {
            simpleLog("Player Left");
        }
    }
}

while (my $line = <STDIN>) {
    processLine($line);
}

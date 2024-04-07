unit class AutoSave;

has $.file is required;
has $.autosave = True;

my $autosave;
my $file;
submethod TWEAK {
    $autosave = $!autosave;
    $file     = $!file;
}

method save {
}

END {
    if $autosave {
        say "Autosaving file '$file'...";
    }
    else {
        say "End without Autosaving file '$file'...";
    }
}



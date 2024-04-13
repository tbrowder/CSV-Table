use Test;

use CSV::Table;

lives-ok {
    CSV::Table.write-config;
}


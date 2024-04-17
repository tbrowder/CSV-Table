use Test;

use CSV::Table;

lives-ok {
    CSV::Table.write-config;
}

lives-ok {
    CSV::Table.write-config: :yml;
}

lives-ok {
    CSV::Table.write-config: :yml;
}


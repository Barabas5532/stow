#!/usr/bin/perl
#
# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.

#
# Test case for dotfiles special processing
#

use strict;
use warnings;

use testutil;

use Test::More tests => 15;
use English qw(-no_match_vars);

use testutil;

init_test_dirs();
cd("$TEST_DIR/target");

my $stow;

#
# process a dotfile marked with 'dot' prefix
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-foo');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('.foo'),
    '../stow/dotfiles/dot-foo',
    => 'processed dotfile'
);

#
# ensure that turning off dotfile processing links files as usual
#

$stow = new_Stow(dir => '../stow', dotfiles => 0);

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-foo');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('dot-foo'),
    '../stow/dotfiles/dot-foo',
    => 'unprocessed dotfile'
);


#
# process folder marked with 'dot' prefix
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles/dot-emacs');
make_file('../stow/dotfiles/dot-emacs/init.el');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('.emacs'),
    '../stow/dotfiles/dot-emacs',
    => 'processed dotfile folder'
);

#
# corner case: paths that have a part in them that's just "$DOT_PREFIX" or
# "$DOT_PREFIX." should not have that part expanded.
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-');

make_path('../stow/dotfiles/dot-.');
make_file('../stow/dotfiles/dot-./foo');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('dot-'),
    '../stow/dotfiles/dot-',
    => 'processed dotfile'
);
is(
    readlink('dot-.'),
    '../stow/dotfiles/dot-.',
    => 'unprocessed dotfile'
);

#
# simple unstow scenario
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-bar');
make_link('.bar', '../stow/dotfiles/dot-bar');

$stow->plan_unstow('dotfiles');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f '../stow/dotfiles/dot-bar' && ! -e '.bar'
    => 'unstow a simple dotfile'
);

#
# stow into existing directory
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('.config');
make_path('../stow/emacs/dot-config/emacs');
make_file('../stow/emacs/dot-config/emacs/init.el');

$stow->plan_stow('emacs');
$stow->process_tasks();
is(
    readlink('.config/emacs'),
    '../../stow/emacs/dot-config/emacs',
    => 'processed dotfile folder into existing folder'
);

#
# unstow from existing directory
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

$stow->plan_unstow('emacs');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -d '.config' && ! -e '.config/stow' &&
    -f '../stow/emacs/dot-config/emacs/init.el'
    => 'unstow from a directory'
);

#
# package containing a dot dir, no folding
#

$stow = new_Stow(dir => '../stow', dotfiles => 1, 'no-folding' => 1);

make_path('../stow/emacs/dot-config/emacs');
make_file('../stow/emacs/dot-config/emacs/init.el');

$stow->plan_stow('emacs');
$stow->process_tasks();
is(
    readlink('.config/emacs/init.el'),
    '../../../stow/emacs/dot-config/emacs/init.el',
    => 'processed dotfile folder without folding'
);

#
# adopt a file in dot folder
#

$stow = new_Stow(dir => '../stow', dotfiles => 1, 'adopt' => 1);

make_path('../stow/vim/dot-vim');
make_file('../stow/vim/dot-vim/vimrc');

make_path('.vim/');
make_file('.vim/vimrc', "vim config1\n");

$stow->plan_stow('vim');
$stow->process_tasks();
is(
    readlink('.vim/vimrc'),
    '../../stow/vim/dot-vim/vimrc',
    => 'adopt file in dot folder symlink'
);

is(
    cat_file('.vim/vimrc'),
    "vim config1\n"
    => "adopt file in dot folder has right contents"
);

#
# adopt a dot file
#

$stow = new_Stow(dir => '../stow', dotfiles => 1, 'adopt' => 1);

make_path('../stow/vim');
make_file('../stow/vim/dot-vimrc');

make_file('.vimrc', "vim config2\n");

$stow->plan_stow('vim');
$stow->process_tasks();
is(
    readlink('.vimrc'),
    '../stow/vim/dot-vimrc',
    => 'adopt dot file symlink'
);

is(
    cat_file('.vimrc'),
    "vim config2\n"
    => "adopt dot file has right contents"
);

#
# adopt a dot file in dot folder
#

$stow = new_Stow(dir => '../stow', dotfiles => 1, 'adopt' => 1);

make_path('../stow/vim/dot-vim');
make_file('../stow/vim/dot-vim/dot-vimrc');

make_path('.vim/');
make_file('.vim/.vimrc', "vim config3\n");

$stow->plan_stow('vim');
$stow->process_tasks();
is(
    readlink('.vim/.vimrc'),
    '../../stow/vim/dot-vim/dot-vimrc',
    => 'adopt dot file in dot folder symlink'
);

is(
    cat_file('.vim/.vimrc'),
    "vim config3\n"
    => "adopt dot file in dot folder has right contents"
);

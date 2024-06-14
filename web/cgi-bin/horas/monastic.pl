#!/usr/bin/perl
use utf8;

# Name : Laszlo Kiss
# Date : 01-25-08
# horas common files to reconcile tempora & sancti
#use warnings;
#use strict "refs";
#use strict "subs";
use FindBin qw($Bin);
use lib "$Bin/..";

# Defines ScriptFunc and ScriptShortFunc attributes.
use DivinumOfficium::Scripting;
my $a = 4;

#*** makeferia()
# generates a name and office for feria
# if there is none
sub makeferia {
  my @nametab = ('Sunday', 'II.', 'III.', 'IV.', 'V.', 'VI.', 'Sabbato');
  my $name = $nametab[$dayofweek];
  if ($dayofweek > 0 && $dayofweek < 6) { $name = "Feria $name"; }
  return $name;
}

#*** psalmi_matutinum_monastic($lang)
# generates the appropriate psalm and lessons
# for the monastic version
sub psalmi_matutinum_monastic {
  $lang = shift;
  $psalmnum1 = $psalmnum2 = -1;
  $psalmnum1 = $psalmnum2 = 0 if (($dayname[0] eq "Quad6") && ($dayofweek > 3));

  #** reads the set of antiphons-psalms from the psalterium
  my %psalmi = %{setupstring($lang, 'Psalterium/Psalmi matutinum.txt')};
  my $dw = $dayofweek;

  my @psalmi = split("\n", $psalmi{"Daym$dw"});
  setbuild("Psalterium/Psalmi matutinum monastic", "dayM$dw", 'Psalmi ord');
  $comment = 1;
  my $prefix = translate('Antiphonae', $lang);

  #** special Adv - Pasc antiphons for Sundays
  if ($dayofweek == 0 && $dayname[0] =~ /(Adv|Pasc)/i) {
    @psalmi = split("\n", $psalmi{$1 . 'm0'});
    setbuild2("Antiphonas Psalmi Dominica special for Adv Pasc");
  }

  #** special antiphons for not Quad weekdays
  if (($dayofweek > 0 && $dayname[0] !~ /Quad/i)
    || $winner =~ /Pasc6-0/)
  {
    my $start = ($dayname[0] =~ /Pasc|Nat[23]\d/i) ? 0 : 8;
    my @p;

    if ($dayname[0] =~ /Pasc/) {
      @p = split("\n", $psalmi{'Daym Pasc'});
    } elsif ($dayname[0] =~ /Nat[23]\d/) {
      @p = split("\n", $psalmi{'Daym Nat'});
    }

    for (my $i = $start; $i < 14; $i++) {
      my $p = $p[$i];
      if ($psalmi[$i] =~ /;;(.*)/s) { $p = ";;$1"; }

      if ($i == 0 || $i == 8) {
        if ($dayname[0] !~ /Nat[23]\d|Pasc0/) {
          $p = alleluia_ant($lang) . $p;
        } else {
          $p = "$p[$i]$p";
        }
      }
      $psalmi[$i] = $p;
    }
    setbuild2("Antiphonas Psalmi weekday special no Quad");
  }

  #** change of versicle for Adv, Quad, Quad5, Pasc
  if ( ($winner =~ /tempora/i && $dayname[0] =~ /(Adv|Quad|Pasc)([0-9])/i)
    || $dayname[0] =~ /(Nat)((?:0?[2-9])|(?:1[0-2]))$/
    || ($dayname[0] =~ /(Epi)1/ && $day > 6 && $day < 13))
  {
    my $name = $1;
    my $i = $2;
    if ($name =~ /Nat/ && $i > 6 && $i < 13) { $name = 'Epi'; }
    if ($name =~ /Quad/i && $i > 4) { $name = 'Quad5'; }
    $i = $dayofweek || 1;
    $_ = $winner;
    s+.*/++;
    s/.txt//;
    if ($_ gt 'Pasc5-4' && $_ lt 'Pasc7-0') { $name = 'Asc' }
    if ($name =~ /Nat|Epi|Asc/ && $i > 3) { $i -= 3; }

    if ($name ne 'Asc') {
      ($psalmi[6], $psalmi[7]) = split("\n", $psalmi{"$name $i Versum"});

      if ($dayofweek == 0) {
        ($psalmi[14], $psalmi[15]) = split("\n", $psalmi{"$name 2 Versum"});
        ($psalmi[17], $psalmi[18]) = split("\n", $psalmi{"$name 3 Versum"});
      }
    } else {
      my %c = (columnsel($lang)) ? %commune : %commune2;
      my @v = split("\n", $c{"Ant Matutinum"});
      my @f = (0, 6, 14, 17);
      ($psalmi[6], $psalmi[7]) = ($v[$f[$i]], $v[$f[$i] + 1]);

      if ($dayofweek == 0) {
        ($psalmi[14], $psalmi[15]) = ($v[14], $v[15]);
        ($psalmi[17], $psalmi[18]) = ($v[17], $v[18]);
      }
    }
    setbuild2("Subst Matutinum Versus $name $dayofweek");
  }

  if ($month == 12 && $day == 24) {
    if ($dayofweek) {
      ($psalmi[6], $psalmi[7]) = split("\n", $psalmi{"Nat24 Versum"});
    } else {
      ($psalmi[17], $psalmi[18]) = split("\n", $psalmi{"Nat24 Versum"});
    }
    setbuild2('Subst Versus Nat24');
    $comment = 1;
  }

  #** special cantica for quad time
  if (exists($winner{'Cantica'})) {
    my $c = split("\n", $winner{Cantica});
    my $i;
    for ($i = 0; $i < 3; $i++) { $psalmi[$i + 16] = $c[$i]; }
  }

  if (
    (
      (
           ($rank > 4.9 || $votive =~ /C8/)
        || (($rank >= 4 && $version =~ /divino/i) || ($rank >= 2 && $version =~ /trident/i))
      )
      && $dayname[1] !~ /feria|sabbato|Die.*infra octavam/i
    )
    && !($dayname[0] =~ /Pasc0/ && $dayofweek > 2)
    && $winner !~ /Pasc6-6/i
    && !($dayname[1] =~ /infra.*Nativitatis/i && $dayofweek && $version !~ /196/)
  ) {
    #** get proper Ant Matutinum for II. and I. class feasts unless it's Wednesday thru Saturday of the Easter Octave
    my ($w, $c) = getproprium('Ant Matutinum', $lang, $version !~ /196/, 1); # for Trid. und Divino also look in Commune

    if ($w) {
      @psalmi = split("\n", $w);
      $comment = $c;
      $prefix .= ' ' . translate('et Psalmi', $lang);
    }

    if ($rule =~ /Ant Matutinum ([0-9]+) special/i) {
      my $ind = $1;
      my %wa = (columnsel($lang)) ? %winner : %winner2;
      my $wa = $wa{"Ant Matutinum $ind"};

      if ($wa) {
        $psalmi[$ind - 1] =~ s/^.*?;;/$wa;;/;
      }
    }
    setbuild2("Antiphonas Psalmi Proprium aut Communem");
  } elsif ($dayname[1] =~ /(?:Die|Feria|Sabbato).*infra octavam|post Octavam Asc|in Vigilia Pent/i
    && !($dayname[0] =~ /Pasc0/ && $dayofweek > 2))
  {
    if (exists($winner{'Ant Matutinum'})) {
      my $start = 0;
      my ($w, $c) = getproprium('Ant Matutinum', $lang, 0, 0);
      my @p = split("\n", $w);

      for (my $i = $start; $i < 14; $i++) {
        my $p = $p[$i];
        if ($psalmi[$i] =~ /;;(.*)/s) { $p = ";;$1"; }

        if ($i == 0 || $i == 8) {
          $p = "$p[$i]$p";
        }
        $psalmi[$i] = $p;
      }
      setbuild2("Antiphonas Psalmi Octavam special");

    }
  }
  setcomment($label, 'Source', $comment, $lang, $prefix);
  nocturn(1, $lang, \@psalmi, (0 .. 7));

  if (
    $rule =~ /12 lectiones/
    || ((($rank >= 4 && $version =~ /divino/i) || ($rank >= 2 && $version =~ /trident/i))
      && $dayname[1] !~ /feria|sabbato|infra octavam/i)
  ) {
    lectiones(1, $lang);    # first Nocturn of 4 lessons (
  } elsif ($dayname[0] =~ /(Pasc[1-6]|Pent)/i
    && monthday($day, $month, $year, ($version =~ /196/) + 0, 0) !~ /^11[1-5]\-/
    && $winner{Rank} !~ /vigil|quat(t?)uor|infra octavam|post octavam asc/i
    && ($winner{Rank} !~ /secunda.*roga/i || $version =~ /196/)
    && $rule !~ /3 lectiones/)
  {
    # from Low Sunday till the first Sunday of November, unless there is a Homily,
    # i.e., outside Ascensiontide and Rogation Monday (pre-55), Pentecost, Vigils, Ember days and Octaves:
    # The change from "summer" to "winter" matins (pre- and post-1960) is tied to the 1st Sunday of November not All Saints' Day.
    # The previous elsif made a mistake and referred to non-existing scriptura of the last week of October
    if ($winner =~ /Tempora/i || !(exists($winner{Lectio94}) || exists($winner{Lectio4}))) {
      brevis_monastic($lang);

      # on a ferial day in "Summer", we have just a Lectio brevis
    } elsif (exists($winner{Lectio94}) || exists($winner{Lectio4})) {
      legend_monastic($lang);

      # on a III. class feast in "Summer", we have the contracted Saint's legend
    }
    push(@s, "\n");
  } else {
    lectiones(0, $lang);

    # the Absolutio and the Benedictions are taken depending on the day of the week;
  }
  $psalmi[14] = $psalmi[15] = '' if ($rule !~ /12 lectiones/);
  nocturn(2, $lang, \@psalmi, (8 .. 15));

  # In case of Matins of 3 nocturns with 12 lessons:
  if (
    $winner{Rule} =~ /12 lectiones/
    || ((($rank >= 4 && $version =~ /divino/i) || ($rank >= 2 && $version =~ /trident/i))
      && $dayname[1] !~ /feria|sabbato|infra octavam/i)
  ) {
    lectiones(2, $lang);    # lessons 5 – 8

    # Tenebrae office:
    # commented out tenebre is Roman Matutinum
    # if (($dayname[0] eq "Quad6") && ($dayofweek > 3))  {
    #   for (16..18) { antetpsalm_mm($psalmi[$_], $_); }
    #   antetpsalm_mm('', -2);
    #   push(@s, $psalmi[19], $psalmi[20], "\n");
    #   lectiones(3, $lang);
    #   return;
    # }

    # Prepare 3rd nocturn canticles (sub una antiphona)
    my ($ant, $p) = split(/;;/, $psalmi[16]);
    my %w = (columnsel($lang)) ? %winner : %winner2;

    if (exists($w{"Ant Matutinum 3N"})) {
      my @t = split("\n", $w{"Ant Matutinum 3N"});
      for (my $i = 0; $i <= $#t; $i++) { $psalmi[16 + $i] = $t[$i]; }
      my ($p1);
      ($ant, $p1) = split(/;;/, $psalmi[16]);
      $p = $p1 || $p;
    }
    $p =~ s/[\(\-]/\,/g;
    $p =~ s/\)//g;

    postprocess_ant($ant, $lang);

    $psalmi[16] = $ant . ';;' . $p;

    nocturn(3, $lang, \@psalmi, (16 .. 18));
    lectiones(3, $lang);          # Homily with responsories #9-#12
    push(@s, '&teDeum', "\n");    # Te Deum comes after the 12th responsory only

    my @e;

    if (exists($w{LectioE})) {    #** set evangelium
      @e = split("\n", $w{LectioE});
    }

    if (!$e[0] || ($e[0] =~ s/^@//)) {

      # if the Evangelium is missing in the Sanctoral or is just a cross-reference
      my ($w, $s) = split(/:/, $e[0]);

      if ($w) {
        $w .= '.txt';
      } else {
        $w = $winner;
      }
      $w =~ s/M//g;    # there is no corresponding folder missa/latin/SanctiM
      $s =~ s/(?:LectioE)?/Evangelium/;
      my %missa = %{setupstring("../missa/$lang", $w)};
      @e = split("\n", $missa{$s});
    }

    my $firstline = shift @e;
    $firstline =~ s/^(v. )?/v./;
    $firstline =~ s/\++/++/;
    push(@s, $firstline, shift @e, "R. " . translate("Gloria tibi Domine", $lang));

    @e = grep { !/^!/ } @e;
    $e[0] =~ s/^(v. )?/v./;
    for ($i = 0; $i < $#e; $i++) { $e[$i] =~ s/~?$/~/ }

    push(@s, @e, "R. " . translate("Amen", $lang), "_", "\$Te decet");
    return;
  }

  # end 2nd nocturn in ferial office
  my ($w, $c) = getproprium('MM Capitulum', $lang, 0, 1);

  if (!$w && $commune) {
    my %c = (columnsel($lang)) ? %commune : %commune2;
    $w = $c{"MM Capitulum"};
  }

  if (!$w) {
    my $name = "";

    if ($dayname[0] =~ /(Adv|Nat|Epi1|Quad|Pasc)/i) {
      $name = " $1";
      if ($dayname[0] =~ /Quad[56]/i) { $name .= '5'; }
      if ($name eq ' Nat' && $day > 6 && $day < 13) { $name = ' Epi'; }
      if ($name eq ' Epi1') { $name = ($day > 6 && $day < 13) ? ' Epi' : ''; }
    }
    my %s = %{setupstring($lang, 'Psalterium/Matutinum Special.txt')};
    $w = $s{"MM Capitulum$name"};
  }
  postprocess_vr($w, $lang) if ($dayname[0] =~ /Pasc/);
  push(@s, "!!Capitulum", $w, "\n");    # print Capitulum, V.R.
}

#*** monstic_lectio3($w, $lang)
# return the legend if appropriate
sub monastic_lectio3 {
  my $w = shift;
  my $lang = shift;
  if ($winner !~ /Sancti/i || exists($winner{Lectio3}) || $rank >= 4 || $rule =~ /(9|12) lectio/i) { return $w; }
  my %w = (columnsel($lang)) ? %winner : %winner2;
  if (exists($w{Lectio94})) { return $w{Lectio94}; }
  if (exists($w{Lectio4})) { return $w{Lectio4}; }
  return $w;
}

#*** absolutio_benedictio($lang)
sub absolutio_benedictio {
  my $lang = shift;

  push(@s, "\n");
  push(@s, '&pater_noster');
  my @a;

  if ($commune =~ /C10/) {
    my %m = (columnsel($lang)) ? %commune : %commune2;
    @a = split("\n", $m{Benedictio});
    setbuild2('Special benedictio');
  } else {
    my %benedictio = %{setupstring($lang, 'Psalterium/Benedictions.txt')};
    my $i =
        ($dayofweek == 1 || $dayofweek == 4) ? 1
      : ($dayofweek == 2 || $dayofweek == 5) ? 2
      : ($dayofweek == 3 || $dayofweek == 6) ? 3
      : 1;
    @a = split("\n", $benedictio{"Nocturn $i"});
    $a[4] = $a[5] if ($i != 3);
  }
  push(@s, "Absolutio. $a[0]");
  push(@s, "\n");
  push(@s, "V. $a[1]");
  push(@s, "Benedictio. $a[4]");
  push(@s, "_");
}

#*** legend_monastic($lang)
sub legend_monastic {
  my $lang = shift;

  #1 lesson
  absolutio_benedictio($lang);
  my %w = (columnsel($lang)) ? %winner : %winner2;
  my $str;

  if (exists($w{Lectio94})) {
    $str = $w{Lectio94};
  } else {
    $str = $w{Lectio4};
    if (exists($w{Lectio5}) && $w{Lectio5} !~ /!/) { $str .= $w{Lectio5} . $w{Lectio6}; }
  }

  $str =~ s/&teDeum\s*//;
  $str =~ s/^(?=\p{Letter})/v. /;
  push(@s, $str, '$Tu autem', '_');

  my $resp = '';

  if (exists($w{Responsory1})) {
    $resp = $w{Responsory1};
  } else {
    my %c = (columnsel($lang)) ? %commune : %commune2;

    if (exists($c{Responsory1})) {
      $resp = $c{Responsory1};
    } else {
      $resp = "Responsory for ne lesson not found!";
    }
  }
  $resp = responsory_gloria($resp, 3);
  matins_lectio_responsory_alleluia($resp, $lang) if alleluia_required($dayname[0], $votive);
  push(@s, $resp);
}

#*** brevis_monstic($lang)
sub brevis_monastic {
  my $lang = shift;
  absolutio_benedictio($lang);
  my $lectio;

  if ($commune =~ /C10/) {
    my %c = (columnsel($lang)) ? %commune : %commune2;
    my $name = getC10readingname();
    my @resp = split(/\n/, $c{'Responsory3'});

    if ($dayname[0] =~ /Pasc/i) {
      ensure_single_alleluia(\$resp[1], $lang);
      ensure_single_alleluia(\$resp[-1], $lang);
    }
    $lectio = join("\n", $c{$name}, "\$Tu autem\n_", @resp);
    setbuild2("Mariae $name");
  } elsif ($commune && $commune !~ /C\d/) {
    my %c = (columnsel($lang)) ? %commune : %commune2;
    $lectio = $c{"MM LB"};
  } else {
    my %b = %{setupstring($lang, 'Psalterium/Matutinum Special.txt')};
    $lectio = $b{"MM LB" . (($dayname[0] =~ /Pasc/) ? " Pasc" : $dayofweek)};
  }
  $lectio =~ s/&Gloria1?/&Gloria1/;
  push(@s, $lectio);
}

#*** regula($lang)
#returns the text of the Regula for the day
sub regula : ScriptFunc {

  my $lang = shift;
  my @a;
  my $t = setfont($largefont, translate("Regula", $lang)) . "\n";
  my $d = $day;
  my $l = leapyear($year);

  if ($month == 2 && $day >= 24 && !$l) { $d++; }
  $fname = sprintf("%02i-%02i", $month, $d);

  if (!-e "$datafolder/Latin/Regula/$fname.txt") {
    if (@a = grep(/$fname/o, do_read("$datafolder/Latin/Regula/Regulatable.txt"))) {
      $fname = substr($a[0], 0, 5);
    } else {
      return $t;
    }
  }

  $fname = checkfile($lang, "Regula/$fname.txt");
  @a = do_read($fname);
  my $title = shift(@a);
  for (@a) { s/^$/_/; }
  $title =~ s/.*#//;
  unshift(@a, $title);
  $t .= join("\n", @a);

  if ($month == 2 && $day == 23 && !$l) {
    $fname = checkfile($lang, "Regula/02-24.txt");
    @a = do_read($fname);
    shift(@a);
    for (@a) { s/^$/_/; }
    $t .= join("\n", @a);
  }

  $t .= "\n" . prayer("Tu autem", $lang);
  $t .= "\n_\n" . prayer("Rubrica Regula", $lang) . "\n_";
  return $t;
}

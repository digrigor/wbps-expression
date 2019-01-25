use strict;
use warnings;
package View::StudiesPage;
use View::Study;
use View::SkippedRuns;
use open ':std', ':encoding(UTF-8)';
use File::Basename;

sub new {
  my ($class, $species, $studies) = @_;
  return bless {species => $species, studies => $studies}, $class;
}

sub to_html {
  my ($self) = @_;
  my $studies_tmpl = HTML::Template->new(path => [dirname (__FILE__) ], filename => "templates/studies.tmpl");

  $studies_tmpl->param(SPECIES => do {
    my $species = $self->{species};
    $species =~ s/_/ /g;
    ucfirst($species)
  });
  
  my @studies_skipped_whole = grep {
     my $skipped_study_id = $_->{study_id};
     my $found = grep {$skipped_study_id eq $_->{study_id}} @{$self->{studies}{passing_checks}};
     not $found
  } @{$self->{studies}{skipped_runs}};

  my @toc = map {{
    ID => $_->{study_id},
    NAME => $_->{title},
  }} @{$self->{studies}{passing_checks}};
  push @toc, {
    ID => "wbps_expression_other",
    NAME => sprintf("%s other studies (not analysed)", scalar @studies_skipped_whole),
  } if @studies_skipped_whole;
  my $studies;

  for my $study (@{$self->{studies}{passing_checks}}){
     $studies .= View::Study->new($study)->to_html . "\n";
  }

  for my $study (@{$self->{studies}{failing_checks}}){
     $studies .= View::Study->new($study)->to_html . "\n";
  }

  $studies_tmpl->param(RUNSTUDIES => $studies);

  my $skip_studies;
  for my $skipped_r (@studies_skipped_whole){
    $skip_studies .= View::SkippedRuns->new($skipped_r)->to_html . "\n";
  }
  $studies_tmpl->param(OTHERSTUDIES => $skip_studies);

  return $studies_tmpl->output;
}

1;

requires "Dancer2" => "0.300005";
requires "Dancer2::Plugin::Database" => "0";
requires "DBD::SQLite" => "0";
requires "Dancer2::Plugin::Auth::Extensible" => "0";
requires "Dancer2::Plugin::Auth::Extensible::Provider::Database" => "0";
requires "Starman" => "0";
requires "Template::Toolkit" => "0";
requires "List::Gen" => "0";
requires "String::Random" => "0";

recommends "YAML"             => "0";
recommends "URL::Encode::XS"  => "0";
recommends "CGI::Deurl::XS"   => "0";
recommends "HTTP::Parser::XS" => "0";

on "test" => sub {
    requires "Test::More"            => "0";
    requires "HTTP::Request::Common" => "0";
};

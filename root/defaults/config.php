<?php

    // refereces:
    // https://tt-rss.org/wiki/GlobalConfig
    // https://git.tt-rss.org/fox/tt-rss.git/tree/classes/Config.php
    // https://srv.tt-rss.org/ttrss-docs/classes/Config.html

    // read vars from runtime environment and putenv those that begin with TTRSS_
    $envvars = glob("/run/s6/container_environment/"."TTRSS_*");
    foreach ($envvars as $envvar) { putenv(basename($envvar).'='.file_get_contents($envvar)); }

    // from https://git.tt-rss.org/fox/tt-rss.git/tree/.docker/app/config.docker.php
    // will override envvars if set here
    $snippets = glob(file_get_contents("/run/s6/container_environment/TTRSSDIR")."/config.d/*.php");
    foreach ($snippets as $snippet) { require_once $snippet; }

    // Plugin-required constants also go here, using define():
    // define('LEGACY_CONSTANT', 'value');

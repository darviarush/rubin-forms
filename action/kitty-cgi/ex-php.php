<?php

frisky_kitty('head Content-Type: text/plain; charset=utf-8');

$abc = "raw data\n\n";
frisky_kitty('write '.strlen($abc));
echo $abc;

echo phpinfo();
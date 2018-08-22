# Test drupal projects with travis

[![Build Status](https://travis-ci.com/thunder/travis.svg?branch=master)](https://travis-ci.com/thunder/travis)

# Versions

[![Latest Stable Version](https://poser.pugx.org/thunder/travis/v/stable)](https://packagist.org/packages/thunder/travis) 
[![Latest Unstable Version](https://poser.pugx.org/thunder/travis/v/unstable)](https://packagist.org/packages/thunder/travis)

# About

Use this package to simplify your drupal module testing on travis. This will run all your standard drupal test on travis
and additionally check your source code for drupal coding style guidelines.

# Prerequisites

To get the most out of this package you should consider to add a few things to your module

## Add your module name to the @group annotation of your test classes.

If your module is called "my_module" add the following annotation to your test classes:

    /**
     * Tests for my_module.
     *
     * @group my_module
     */
    class MyModuleTest extends ...

## Add a composer.json to your module. 
We use that file to automate different things. We parse the module name from it and we will automatically download 
required drupal modules before running the tests. If you require javascript libraries require them with [asset-packagist](https://asset-packagist.org)

A composer.json could look like the following:

    {
        "name": "drupal/my_module",
        "description": "The description of my_module",
        "type": "drupal-module",
        "license": "GPL-2.0-or-later",
        "require": {
            "drupal/another_module": "^2.0",
            "npm-asset/javascript-library": "^1.0"
        }
    }

## Do not use deprecated TestBase classes
Only not deprecated (as of drupal 8.6) TestBase classes are tested. Especially the deprecated JavascriptTestBase
is not supported, please use WebDriverTestBase instead. See [JavascriptTestBase is deprecated in favor of WebDriverTestBase](https://www.drupal.org/node/2945059)

# Setup
All you need to do is to copy the .travis.yaml.dist to your project root folder and rename it to .travis.yaml.
If your module meets all the prerequisites, you should be done. Otherwise you might need to provide some environment variables.
See below for possible configurations.   

# Differences to LionsAd/drupal_ti
While the general approach is very similar to drupal_ti, we differ in some regards.
 
 - If you want to run deprecated TesBase classes, use drupal_ti.
 - When using WebDriverTestBase and Drupal > 8.6 (which needs selenium instead of phantom.js) use this package.
 - If you want a simple travis.yml file, that works without any configuration, use this package.
 - If you have a linux installation on your development computer, you can directly use this test runner! All you need is php command line client, composer and docker.
   If you have all this installed on your local machine, just do <code>composer global require thunder/travis</code> add the global 
   composer directory to your $PATH and call <code>test-drupal-module</code> from within your modules directory. Everything will be build, installed
   and tested automatically.
 
# Configuration

We try to run without configuration as much as possible, but we still have a lot of configuration options, if your module
requires some special treatment, or if your testing environment is not travis (or travis changed some default values)

The simplest way to run the tests is to just call <code>test_drupal_module</code> in your .travis.yml. 
This will do everything, but it is actually devided into several steps which can be called separately.
The steps are the following

## prepare
Prepares the testing environment. Starts selenium and mysql if necessary and tweaks php on travis 

## coding_style
Tests php and javascript coding styles

## build
Builds the drupal installation with drupal project, adds all dependencies from the module.

## install
Installs drupal with the minimal profile, as required by simpletest module. Enables simpletest module

## start_web_server
Starts a webserver pointing to the installed drupal.

## run_tests
Runs the tests
  
 
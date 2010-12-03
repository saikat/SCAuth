/*
 * Jakefile
 * SCAuth
 *
 * Created by Saikat Chakrabarti on April 7, 2010.
 *
 * See LICENSE file for license information.
 *
 */

var OS = require("os"),
    ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    CLEAN = require("jake/clean").CLEAN,
    FileList = JAKE.FileList,
    framework = require("cappuccino/jake").framework,
    browserEnvironment = require("objective-j/jake/environment").Browser,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug";

framework ("SCAuth", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "SCAuth.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("SCAuth");
    task.setIdentifier("com.saikat.SCAuth");
    task.setVersion("0.1");
    task.setAuthor("Saikat Chakrabarti");
    task.setEmail("saikat@gomockingbird.com");
    task.setSummary("A collection of re-usable views, controls & utilities for Cappuccino.");
    task.setSources(new FileList("**/*.j"));
    task.setResources(new FileList("Resources/**/*"));
    //task.setEnvironments([browserEnvironment]);
    //task.setFlattensSources(true);
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("debug", function()
{
    ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("default", ["release"]);

task ("build", ["SCAuth"]);

task ("symlink", ["release", "debug"], function()
{
    // TODO: this should not be hardcoded to /usr/local - not sure how
    // to actually find the path to narwhal right now though.
    var frameworksPath = FILE.join("", "usr", "local", "narwhal", "packages", "cappuccino", "Frameworks");

    ["Release", "Debug"].forEach(function(aConfig)
    {
        print("Symlinking " + aConfig + " ...");

        if (aConfig === "Debug")
            frameworksPath = FILE.join(frameworksPath, aConfig);

        var buildPath = FILE.absolute(FILE.join("Build", aConfig, "SCAuth")),
            symlinkPath = FILE.join(frameworksPath, "SCAuth");

        OS.system(["sudo", "ln", "-s", buildPath, symlinkPath]);
    });
});

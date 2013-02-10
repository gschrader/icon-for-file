//
//  main.m
//  iconforfile
//
//  Created by Glen Schrader on 01/19/13.
//  Copyright (c) 2013 Glen Schrader. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NSData+Base64.h"
#import "GBOptionsHelper.h"
#import "GBCommandLineParser.h"
#import "GBSettings.h"

int main(int argc, const char *argv[]) {

    @autoreleasepool {
        GBSettings *factoryDefaults = [GBSettings settingsWithName:@"Factory" parent:nil];
        [factoryDefaults setInteger:16 forKey:@"size"];
        GBSettings *settings = [GBSettings settingsWithName:@"CmdLine" parent:factoryDefaults];

        GBOptionsHelper *options = [[GBOptionsHelper alloc] init];
        options.applicationVersion = ^{
            return @"1.0";
        };
        options.applicationBuild = ^{
            return @"100";
        };
        options.printValuesHeader = ^{
            return @"%APPNAME version %APPVERSION (build %APPBUILD)\n";
        };
        options.printValuesArgumentsHeader = ^{
            return @"Running with arguments:\n";
        };
        options.printValuesOptionsHeader = ^{
            return @"Running with options:\n";
        };
        options.printValuesFooter = ^{
            return @"\nEnd of values print...\n";
        };
        options.printHelpHeader = ^{
            return @"Usage %APPNAME [OPTIONS] <arguments separated by space>";
        };

        GBOptionDefinition definitions[] = {
                {'f', @"file", @"icon by file, complete path", GBValueRequired},
                {'t', @"type", @"icon by type (i.e. file extension)", GBValueRequired},
                {'o', @"output", @"output file, Write output to file.  Default is stdout", GBValueRequired},
                {'s', @"size", @"pixel size. Default is 16", GBValueRequired},
                {'b', @"base64", @"output in base64", GBValueNone},
                {'v', @"printVersion", @"Display version and exit", GBValueNone | GBOptionNoPrint},
                {'h', @"printHelp", @"Display this help and exit", GBValueNone | GBOptionNoPrint},
                {0, nil, nil, 0}
        };
        [options registerOptionsFromDefinitions:definitions];

        GBCommandLineParser *parser = [[GBCommandLineParser alloc] init];
        [options registerOptionsToCommandLineParser:parser];
        __block BOOL commandLineValid = YES;
        [parser parseOptionsWithArguments:argv count:argc block:^(GBParseFlags flags, NSString *option, id value, BOOL *stop) {
            switch (flags) {
                case GBParseFlagUnknownOption:
                    printf("Unknown command line option %s, try --help!\n", option.UTF8String);
                    commandLineValid = NO;
                    break;
                case GBParseFlagMissingValue:
                    printf("Missing value for command line option %s, try --help!\n", option.UTF8String);
                    commandLineValid = NO;
                    break;
                case GBParseFlagArgument:
                    [settings addArgument:value];
                    break;
                case GBParseFlagOption:
                    [settings setObject:value forKey:option];
                    break;
            }
        }];
        if (!commandLineValid) return 1;

        if ([settings boolForKey:@"printHelp"] || argc == 1) {
            [options printHelp];
            return 0;
        }

        if ([settings boolForKey:@"printVersion"]) {
            [options printVersion];
            return 0;
        }

        id file = [settings objectForLocalKey:@"file"];
        id type = [settings objectForLocalKey:@"type"];
        id output = [settings objectForLocalKey:@"output"];
        CGFloat size = [settings floatForKey:@"size"];
        if (size == 0) {
            size = 16;
        }

        if (argc == 0) {
            [options printHelp];
            return 0;
        }

        if (type == nil && file == nil) {
            [options printHelp];
            return 0;
        }

        NSImage *image;
        if (file) {
            image = [[NSWorkspace sharedWorkspace] iconForFile:file];
        }

        if (type) {
            image = [[NSWorkspace sharedWorkspace] iconForFileType:type];
        }

        NSImage *resizedImage = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];
        NSSize originalSize = [image size];

        [resizedImage lockFocus];
        [image drawInRect:NSMakeRect(0, 0, size, size) fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height) operation:NSCompositeSourceOver fraction:1.0];
        [resizedImage unlockFocus];

        NSData *resizedData = [resizedImage TIFFRepresentation];
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:resizedData];

        // hard code png for now
        NSData *imageData = [imageRep representationUsingType:NSPNGFileType properties:nil];

        NSFileHandle *out;
        if (output == nil) {
            out = [NSFileHandle fileHandleWithStandardOutput];
        } else {
            if (![[NSFileManager defaultManager] fileExistsAtPath:output]) {
                [[NSFileManager defaultManager] createFileAtPath:output contents:nil attributes:nil];
            }
            out = [NSFileHandle fileHandleForWritingAtPath:output];
            [out truncateFileAtOffset:0];
        }

        if ([settings boolForKey:@"base64"]) {
            [out writeData:[[imageData base64EncodedString] dataUsingEncoding:NSUTF8StringEncoding]];
            [out closeFile];
        } else {
            [out writeData:imageData];
        }
    }

    return 0;
}

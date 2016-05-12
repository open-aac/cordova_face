//
//  CoughDropMisc.m
//  CoughDrop
//
//  Created by Brian Whitmer on 5/12/16.
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>

@interface CoughDropMisc : CDVPlugin
@end

@implementation CoughDropMisc {
    NSString* changeCallbackId;
}

- (void)status:(CDVInvokedUrlCommand*)command
{
    // return success({ready: true}) or error({ready:false}) depending on whether init has been called
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"ok"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)listFiles:(CDVInvokedUrlCommand*)command
{
    
    // just testing with reading in values from a hash object and returning a hash result
    
    NSDictionary* options = nil;
    options = [command argumentAtIndex:0];
    NSString* dir = [options objectForKey:@"dir"];

    NSMutableDictionary* result = [self recursivePathsForResourcesOfType:nil inDirectory:dir];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSMutableDictionary *)recursivePathsForResourcesOfType:(NSString *)type inDirectory:(NSString *)directoryPath{
    NSMutableDictionary* result = [[NSMutableDictionary alloc]init];
    
    NSMutableArray *filePaths = [[NSMutableArray alloc] init];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    long total_size = 0;
    
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject]) != nil){
        NSString* full_path = [directoryPath stringByAppendingPathComponent:filePath];
        long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:full_path error:nil][NSFileSize] longValue];
        total_size = total_size + fileSize;
        [filePaths addObject:full_path];
    }

    [result setObject:filePaths forKey:@"files"];
    [result setObject:[NSNumber numberWithLong:total_size] forKey:@"size"];

    return result;
}

@end
//
//  fileOps.m
//  sonar1
//
//  Created by lio 123 on 11/11/2012.
//
//

#import "fileOps.h"

@implementation fileOps

@synthesize fileMgr;
@synthesize homeDir;
@synthesize fileName;
@synthesize filePath;


-(NSString*) getDocumentDir
{
    fileMgr = [NSFileManager defaultManager];
    homeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    return homeDir;
}

-(void) writeToStringfile:(NSMutableString*)textToWrite
{
    filePath = [[NSString alloc] init];
    
    filePath = [self.getDocumentDir stringByAppendingPathComponent:self.setFileName];
    
    if ([fileMgr fileExistsAtPath: filePath] == YES)
    {
        NSLog(@"file exists");
    }
    else
    {
        NSLog(@"%@%@",@"file not found ",filePath);
        [fileMgr createFileAtPath:filePath contents:nil attributes:nil] ;
    }
    NSFileHandle *hFile = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    if (hFile == nil)
        NSLog(@"error file open");
    
    [hFile seekToEndOfFile];
    [hFile writeData: [textToWrite dataUsingEncoding:NSUTF8StringEncoding]];
    [hFile closeFile];
    
}

-(NSString*) readFormFile
{
    filePath = [[NSString alloc] init];
    NSError *error;
    NSString *title;
    filePath = [self.getDocumentDir stringByAppendingPathComponent:self.setFileName];
    NSString *txtInFile = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUnicodeStringEncoding error:&error];
    
    if(!txtInFile)
    {
        UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:title message:@"Unable to get text from file." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [tellErr show];
    }
    return txtInFile;
}

-(NSString*) setFileName
{
    fileName = @"mytextfile.txt";
    return fileName;
}

@end

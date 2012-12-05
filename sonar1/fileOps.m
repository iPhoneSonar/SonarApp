//
//  fileOps.m
//  sonar1
//
//  Created by lio 123 on 11/11/2012.
//
//
#ifndef DEBUG
#define NSLog(...)
#endif

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

-(void) WriteString:(NSMutableString*)textToWrite ToFile:(NSString*)ToFileName
{
    filePath = [[NSString alloc] init];    
    filePath = [self.getDocumentDir stringByAppendingPathComponent:ToFileName];
    NSLog(@"Path=%@", filePath);
    if ([fileMgr fileExistsAtPath: filePath] == YES)
    {
        if ([fileMgr removeItemAtPath:filePath error:NULL] == YES)
        {
            NSLog(@"file %@ deleted", ToFileName);
        }
        else
        {
            NSLog(@"error deleting file: %@", ToFileName);
        }
    }
    else
    {
        NSLog(@"file %@ did not exist, not deleted", ToFileName);
    }    
    [fileMgr createFileAtPath:filePath contents:nil attributes:nil] ;
    if ([fileMgr fileExistsAtPath: filePath] == YES)
    {
        NSLog(@"file %@ created", ToFileName);
    }
    else
    {
        NSLog(@"error creating file %@", ToFileName);
    }   
    
    NSFileHandle *hFile = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    if (hFile == nil)
        NSLog(@"error open file %@", ToFileName);
    [hFile seekToEndOfFile];
    [hFile writeData: [textToWrite dataUsingEncoding:NSUTF8StringEncoding]];
    [hFile closeFile];
    
}

-(NSString*) readFormFile:(NSString*)Name
{
    filePath = [[NSString alloc] init];
    NSError *error;
    NSString *title;
    filePath = [self.getDocumentDir stringByAppendingPathComponent:Name];
    NSString *txtInFile = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUnicodeStringEncoding error:&error];
    
    if(!txtInFile)
    {
        NSString* Message=[@"Unable to get text from file: " stringByAppendingString:Name];
        UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:title message:Message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [tellErr show];
    }
    return txtInFile;
}

-(NSString*) setFileName
{
    fileName = @"Datei.txt";
    return fileName;
}

-(NSMutableString*) FloatArrayToString:(float*)AIn OfArraySize:(int)SizeA;
{
    NSString *Sout= [NSString stringWithFormat:@"%.5f", AIn[0]];
    for (int i=1; i<SizeA;i++)
    {        
        Sout=[Sout stringByAppendingString:@"\r\n"];
        Sout=[Sout stringByAppendingString:[NSString stringWithFormat:@"%.5f", AIn[i]]];
    }
#ifndef NODEBUG
    NSLog(@"%@",Sout);
    NSLog(@"Converted FloatArrayToString");
#endif
    return [Sout mutableCopy];
}

-(NSMutableString*) Sint16ArrayToString:(SInt16*)AIn OfArraySize:(int)SizeA;
{
    NSString *Sout= [NSString stringWithFormat:@"%.i", AIn[0]];
    for (int i=1; i<SizeA;i++)
    {
        Sout=[Sout stringByAppendingString:@"\r\n"];
        Sout=[Sout stringByAppendingString:[NSString stringWithFormat:@"%i", AIn[i]]];
    }
#ifndef NODEBUG
    NSLog(@"%@",Sout);
    NSLog(@"Converted FloatArrayToString");
#endif
    return [Sout mutableCopy];
}


@end

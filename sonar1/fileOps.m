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

-(void) WriteString:(NSMutableString*)textToWrite ToFile:(NSString*)ToFileName
{
    filePath = [[NSString alloc] init];
    
    filePath = [self.getDocumentDir stringByAppendingPathComponent:ToFileName];
    
    if ([fileMgr fileExistsAtPath: filePath] == YES)
    {
        NSLog(@"file %@ exists", ToFileName);
    }
    else
    {
        NSLog(@"%@%@",@"file not found ",filePath);
        [fileMgr createFileAtPath:filePath contents:nil attributes:nil] ;
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
        Sout=[Sout stringByAppendingString:@"\n"];
        Sout=[Sout stringByAppendingString:[NSString stringWithFormat:@"%.5f", AIn[i]]];
    }
    //NSLog(@"FloatArrayToString: %@",Sout);
    NSLog(@"Converted FloatArrayToString");
    return [Sout mutableCopy];
}


@end

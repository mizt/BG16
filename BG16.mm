#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import <vector>
#import <string>

int main(int argc, char *argv[]) {
    
    @autoreleasepool {
        
            
        std::string JSON = R"({"meshes":[{"primitives":[{"attributes":{"POSITION":0,"RGB":1}}]}],"accessors":[{"bufferView":0,"componentType":5126,"count":0,"type":"VEC3"},{"bufferView":1,"componentType":5126,"count":0,"type":"VEC3"},],"bufferViews":[{"buffer":0,"byteLength":0,"byteOffset":0},{"buffer":0,"byteLength":0,"byteOffset":0},{"buffer":0,"byteLength":0,"byteOffset":0}],"buffers":[{"byteLength":0}]})";
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[[NSString stringWithUTF8String:JSON.c_str()] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
        
        if(dict) {
            
            std::vector<simd::float3> _v;
            std::vector<simd::uchar3> _rgb;
            std::vector<simd::uint3> _f;
            
            std::vector<unsigned short> v16;
            std::vector<unsigned char> rgb;

            NSCharacterSet *WHITESPACE = [NSCharacterSet whitespaceCharacterSet];
            
            NSString *data = [NSString stringWithContentsOfFile:@"./BG.obj" encoding:NSUTF8StringEncoding error:nil];
            NSArray *lines = [data componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
                        
            for(int k=0; k<lines.count; k++) {
                NSArray *arr = [lines[k] componentsSeparatedByCharactersInSet:WHITESPACE];
                if([arr count]>0) {
                    if([arr[0] isEqualToString:@"v"]) {
                        if([arr count]>=4) {
                            _v.push_back(simd::float3{
                                [arr[1] floatValue],
                                [arr[2] floatValue],
                                [arr[3] floatValue]
                            });
                            
                            if([arr count]>=7) {
                                _rgb.push_back(simd::uchar3{
                                    (unsigned char)([arr[4] floatValue]*255.0),
                                    (unsigned char)([arr[5] floatValue]*255.0),
                                    (unsigned char)([arr[6] floatValue]*255.0),
                                });
                            }
                            else {
                                _rgb.push_back(simd::uchar3{
                                    (unsigned char)(0x80),
                                    (unsigned char)(0x80),
                                    (unsigned char)(0x80),
                                });
                            }
                        }
                    }
                    else if([arr[0] isEqualToString:@"f"]) {
                        if([arr count]==4) {
                            
                            NSArray *a = [arr[1] componentsSeparatedByString:@"/"];
                            NSArray *b = [arr[2] componentsSeparatedByString:@"/"];
                            NSArray *c = [arr[3] componentsSeparatedByString:@"/"];
                            
                            _f.push_back(simd::uint3{
                                (unsigned int)[a[0] intValue]-1,
                                (unsigned int)[b[0] intValue]-1,
                                (unsigned int)[c[0] intValue]-1
                            });
                            
                        }
                    }
                }
            }
            
            for(int n=0; n<_f.size(); n++) {
                
                _Float16 v[9] = {
                    (_Float16)_v[_f[n].x].x,(_Float16)_v[_f[n].x].y,(_Float16)_v[_f[n].x].z,
                    (_Float16)_v[_f[n].y].x,(_Float16)_v[_f[n].y].y,(_Float16)_v[_f[n].y].z,
                    (_Float16)_v[_f[n].z].x,(_Float16)_v[_f[n].z].y,(_Float16)_v[_f[n].z].z,
                };
                
                v16.push_back(*((unsigned short *)(v+0)));
                v16.push_back(*((unsigned short *)(v+1)));
                v16.push_back(*((unsigned short *)(v+2)));
                
                v16.push_back(*((unsigned short *)(v+3)));
                v16.push_back(*((unsigned short *)(v+4)));
                v16.push_back(*((unsigned short *)(v+5)));
                
                v16.push_back(*((unsigned short *)(v+6)));
                v16.push_back(*((unsigned short *)(v+7)));
                v16.push_back(*((unsigned short *)(v+8)));
                
                rgb.push_back(_rgb[_f[n].x].x);
                rgb.push_back(_rgb[_f[n].x].y);
                rgb.push_back(_rgb[_f[n].x].z);
                
                rgb.push_back(_rgb[_f[n].y].x);
                rgb.push_back(_rgb[_f[n].y].y);
                rgb.push_back(_rgb[_f[n].y].z);
                
                rgb.push_back(_rgb[_f[n].z].x);
                rgb.push_back(_rgb[_f[n].z].y);
                rgb.push_back(_rgb[_f[n].z].z);
            }
            
            unsigned int offset = 0;
            
            dict[@"bufferViews"][0][@"byteOffset"] = [NSNumber numberWithInt:offset];
            dict[@"bufferViews"][0][@"byteLength"] = [NSNumber numberWithInt:(v16.size())*sizeof(unsigned short)];
            
            dict[@"accessors"][0][@"count"] = [NSNumber numberWithInt:v16.size()/3];
            NSLog(@"%d",[dict[@"accessors"][0][@"count"] intValue]);
            
            while(v16.size()%4!=0) { v16.push_back(0); }
            offset+=v16.size()*sizeof(unsigned short);
            
            dict[@"bufferViews"][1][@"byteOffset"] = [NSNumber numberWithInt:offset];
            dict[@"bufferViews"][1][@"byteLength"] = [NSNumber numberWithInt:rgb.size()*sizeof(unsigned char)];
            dict[@"accessors"][1][@"count"] = [NSNumber numberWithInt:rgb.size()/3];
            NSLog(@"%d",[dict[@"accessors"][1][@"count"] intValue]);
            
            while(rgb.size()%4!=0) { rgb.push_back(0); }
            offset+=rgb.size()*sizeof(unsigned char);
            
            dict[@"buffers"][0][@"byteLength"] = [NSNumber numberWithInt:offset];
            
            NSMutableData *json = [[NSMutableData alloc] init];
            [json appendData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingWithoutEscapingSlashes|NSJSONWritingSortedKeys error:nil]];
            
            while(json.length%4!=0) { [json appendBytes:new const char[1]{0x20} length:1]; }
            
            NSMutableData *glb = [[NSMutableData alloc] init];
            [glb appendBytes:new const char[4]{'B','G','1','6'} length:4];
            [glb appendBytes:new unsigned int[1]{2} length:4];
            [glb appendBytes:new unsigned int[1]{((4*7)+(unsigned int)json.length)+offset} length:4];
            [glb appendBytes:new unsigned int[1]{(unsigned int)json.length} length:4];
            [glb appendBytes:new const char[4]{'J','S','O','N'} length:4];
            [glb appendBytes:json.bytes length:json.length];
            [glb appendBytes:new unsigned int[1]{offset} length:4];
            [glb appendBytes:new const char[4]{'B','I','N',0} length:4];
            [glb appendBytes:v16.data() length:v16.size()*sizeof(unsigned short)];
            [glb appendBytes:rgb.data() length:rgb.size()*sizeof(unsigned char)];
            
            [glb writeToFile:@"./docs/BG.bin" atomically:YES];
            
            glb = nil;
            json = nil;
            dict = nil;
        }
    }
}
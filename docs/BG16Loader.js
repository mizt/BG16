const U8toU32 = (arr,offset)=>{ return arr[offset+3]<<24|arr[offset+2]<<16|arr[offset+1]<<8|arr[offset]; };
const U32 = new Uint32Array(1);
const U16toF32 = (u16)=>{
	U32[0] = (u16&0x8000)<<16|((((u16>>10)&0x1F)-15+127)&0xFF)<<23|(u16&0x3FF)<<13;
	return (new Float32Array(U32.buffer))[0];
}

export const BGLoader = Object.freeze({
	
	parse:(url,data,init)=>{
		
		const U8 = new Uint8Array(data);
		
		if(new TextDecoder().decode(U8.slice(0,4))==="BG16") {
			
			const size = U8toU32(U8,4*3);
			if(new TextDecoder().decode(U8.slice(4*4,4*4+4))==="JSON") {
				const json = JSON.parse(new TextDecoder().decode(U8.slice(4*5,4*5+size)));
				if(new TextDecoder().decode(U8.slice(4*5+size+4*1,4*5+size+4*1+3))==="BIN") {
					
					const offset = 4*5+size+4*2;
					const bufferViews = json["bufferViews"];
					const byteOffsets = [bufferViews[0]["byteOffset"],bufferViews[1]["byteOffset"],bufferViews[2]["byteOffset"]];
					const byteLengths = [bufferViews[0]["byteLength"],bufferViews[1]["byteLength"],bufferViews[2]["byteLength"]];

					
					if(+(json["accessors"][0]["count"])===+(json["accessors"][1]["count"])) {
						
						const U16 = (new Uint16Array(data)).slice(offset>>1);

						const v16  = U16.slice(byteOffsets[0]>>1,(byteOffsets[0]+byteLengths[0])>>1);
						const rgb8 = U8.slice(offset+byteOffsets[1],(offset+byteOffsets[1]+byteLengths[1]));
						
						const len = +(json["accessors"][0]["count"]);
						
						const v = new Float32Array(len*3);
						for(var n=0; n<v.length; n++) {
							v[n] = U16toF32(v16[n]);
						}
						
						const rgb = new Float32Array(len*3);
						for(var n=0; n<rgb.length; n++) {
							rgb[n] = rgb8[n]/255.0;
						}
						
						const result = {};
						
						if(len<=0xFFFF) {
							
							const f = new Uint16Array(len);
							for(var n=0; n<f.length; n++) { f[n] = n; }
							
							result[url] = {
								"v":v,
								"rgb":rgb,
								"f":f,
								"bytes":2
							}
						}
						else {
							
							const f = new Uint32Array(len);
							for(var n=0; n<f.length; n++) { f[n] = n; }
							
							result[url] = {
								"v":v,
								"rgb":rgb,
								"f":f,
								"bytes":4
							}
						}
						
						init(result);
					}
				}
			}
		}
	},
	
	load:(url,init)=>{
		
		let list = [];
		
		if(typeof(url)==="string") {
			list.push(url);
		}
		else if(Array.isArray(url)) {
			list = url;
		}
						
		if(list.length>=1) {
			
			let loaded = 0;
			let data = {};
			
			const onload = (result) => {
				if(result) {
					const key = Object.keys(result)[0];
					data[key] = result[key];
					loaded++;
					if(loaded===list.length) {
						init(data);
					}
				}
			};
			
			const load = (url) => {
				fetch(url).then(response=>response.blob()).then(data=>{
					const fr = new FileReader();
					fr.onloadend = ()=>{
						BGLoader.parse(url,fr.result,onload);
					};
					fr.readAsArrayBuffer(data)
				}).catch(error=>{
					console.error(error);
				});
			}
			
			for(var n=0; n<list.length; n++) {
				load(list[n]);
			}
		}
	}
});
//  -----
// | DDS |
//  -----

// NOTE: only DXT5 supported atm

// STRUCTS ----------------------------------------------------

DDS_Image :: struct {
    dwMagic  : u32;
    header   : DDS_HEADER;
    header10 : DDS_HEADER_DXT10;
    bdata    : [] u8;
    bdata2   : [] u8;
}

DDS_HEADER :: struct {
    dwSize              : u32;
    dwFlags             : u32;
    dwHeight            : u32;
    dwWidth             : u32;
    dwPitchOrLinearSize : u32;
    dwDepth             : u32;
    dwMipMapCount       : u32;
    dwReserved1         : [11] u32;
    ddspf               : u32;
    dwCaps              : u32;
    dwCaps2             : u32;
    dwCaps3             : u32; // NOTE: Unused
    dwCaps4             : u32; //
    dwReserved2         : u32; //
}

DDS_HEADER_DXT10 :: struct {
    dxgiFormat: DXGI_FORMAT;
    resourceDimension: D3D12_RESOURCE_DIMENSION;
    miscFlag   : u32;
    arraySize  : u32;
    miscFlags2 : u32;
}

DDS_HEADER_FLAGS :: enum u32 {
    DDSD_CAPS         :: 0x1;
    DDSD_HEIGHT	      :: 0x2;
    DDSD_WIDTH	      :: 0x4;
    DDSD_PITCH	      :: 0x8;
    DDSD_PIXELFORMAT  :: 0x1000;
    DDSD_MIPMAPCOUNT  :: 0x20000;
    DDSD_LINEARSIZE   :: 0x80000;
    DDSD_DEPTH	      :: 0x800000;
}

DDS_HEADER_CAPS :: enum u32 {
    DDSCAPS_COMPLEX :: 0x8;
    DDSCAPS_MIPMAP  :: 0x400000;
    DDSCAPS_TEXTURE :: 0x1000;
}

DDS_HEADER_CAPS2 :: enum u32 {
    DDSCAPS2_CUBEMAP           :: 0x200;
    DDSCAPS2_CUBEMAP_POSITIVEX :: 0x400;
    DDSCAPS2_CUBEMAP_NEGATIVEX :: 0x800;
    DDSCAPS2_CUBEMAP_POSITIVEY :: 0x1000;
    DDSCAPS2_CUBEMAP_NEGATIVEY :: 0x2000;
    DDSCAPS2_CUBEMAP_POSITIVEZ :: 0x4000;
    DDSCAPS2_CUBEMAP_NEGATIVEZ :: 0x8000;
    DDSCAPS2_VOLUME            :: 0x200000;
}

DDS_PIXELFORMAT :: struct {
    dwSize        : u32;
    dwFlags       : u32;
    dwFourCC      : u32;
    dwRGBBitCount : u32;
    dwRBitMask    : u32;
    dwGBitMask    : u32;
    dwBBitMask    : u32;
    dwABitMask    : u32;
}

DDS_PIXELFORMAT_FLAGS :: enum u32 {
    DDPF_ALPHAPIXELS :: 0x1;
    DDPF_ALPHA       :: 0x2;
    DDPF_FOURCC      :: 0x4;
    DDPF_RGB         :: 0x40;
    DDPF_YUV         :: 0x200;
    DDPF_LUMINANCE   :: 0x20000;
}

// PROCEDURES -------------------------------------------------

/*
====================
memcpy_eat

Convenience, memcpy() then advance cursor to end of copy region.
====================
*/
memcpy_eat :: (dst: *void, cursor: *void, size: s64) {
    memcpy(dst, cursor, size);
    cursor += size;
}

/*
====================
dds_from_file

Convenience, read_entire_file() then dds_from_memory().
====================
*/
dds_from_file :: (path: string) -> DDS_Image {
    bytecode := read_entire_file(path);
    dds_from_memory(bytecode.data, bytecode.count);
}

// TODO avoid stack allocations?
dds_from_memory :: (data: *void, length: u64) -> DDS_Image {
    
    // Check magic for valid dds
    cursor : *u8 = data;
    magic: u32;
    memcpy_eat(*magic, cursor, size_of(u32));
    if magic != 0x20534444 return null;

    dds_image: DDS_Image;
    memcpy_eat(*dds_image.header, cursor, size_of(DDS_HEADER));

    // TODO: check validity of header? might be unneccessary
    // Check if header10
    if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "DX10" {
        memcpy_eat(*dds_image.header10, cursor, size_of(DDS_HEADER_DXT10));
    }

    width  := max(1, dds_image.header.width);
    height := max(1, dds_image.header.height);
    depth  := max(1, dds_image.header.depth);

    dds_image.data = alloc(width*height*depth*4);
    
    if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "DXT1" {} // dds_parse_dxt1
    else if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "DXT2" {} // dds_parse_dxt2
    else if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "DXT3" {} // dds_parse_dxt3
    else if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "DXT4" {} // dds_parse_dxt4
    else if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "DXT5" {
        dds_parse_dxt5(dds_image, cursor, length-(cursor-data), width, height, depth);
    }
    else if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "DX10" {} // dds_parse_dx10
    else if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "ATI1" {} // dds_parse_ati1
    else if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "ATI2" {} // dds_parse_ati2
    else if (dds_image.header.ddspf.flags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == "A2XY" {} // dds_parse_ati3
    // else dds_parse_uncompressed

    return dds_image;
}

#scope_module

// @Speed
dds_parse_dxt5 :: (
    image: DDS_Image,
    data: *void,
    data_length: u64,
    width: u32,
    height: u32,
    depth: u32
) {
    
    blocks_x := max(1, width/4);
    blocks_y := max(1, height/4);

    // TODO alternative to nested loops?
    for z: 0..depth-1 {
	for x: 0..blocks_x-1 {
	    for y: 0..blocks_y-1 {
		
		color0, color1, codes: u32;
		alpha_codes: u64;

		block_offset := (y * blocks_x + x) * 16;
		alpha0 := data[block_offset];
		alpha1 := data[block_offset + 1];
		memcpy(*alpha_data, data + block_offset, 8);
		memcpy(*color0, data + block_offset + 8, 2);
		memcpy(*color1, data + block_offset + 10, 2);
		memcpy(*codes, data + block_offset + 12, 4);

		r0 := (color0 & 0b1111100000000000) >> 8;
		g0 := (color0 & 0b0000011111100000) >> 3;
		b0 := (color0 & 0b0000000000011111) << 3;
		r1 := (color1 & 0b1111100000000000) >> 8;
		g1 := (color1 & 0b0000011111100000) >> 3;
		b1 := (color1 & 0b0000000000011111) << 3;

		for b: 0..15 {
		    
		    px_index := (z * height * width +
				 (img_height - ((y * 4) + b / 4) - 1)
				 * img_width + x * 4 + b % 4) * 4;
		    code := (codes >> (2 * b)) & 0b0011;
		    alpha_code = (alpha_codes >> (3 * b)) & 0b0111;

		    alpha := 0xFF;
		    if code == {
			case 0;
			  image.pixels[px_index] = r0;
			  image.pixels[px_index + 1] = g0;
			  image.pixels[px_index + 2] = b0;
			  alpha = alpha0;
			case 1;
			  image.pixels[px_index] = r1;
			  image.pixels[px_index + 1] = g1;
			  image.pixels[px_index + 2] = b1;
			  alpha = alpha1;
			case 2;
			  image.pixels[px_index] = (2 * r0 + r1) / 3;
			  image.pixels[px_index + 1] = (2 * g0 + g1) / 3;
                          image.pixels[px_index + 2] = (2 * b0 + b1) / 3;
			  if alpha0 > alpha1 alpha = ((8 - alpha_code) * alpha0 + (alpha_code - 1) * alpha1) / 7;
			  else {
			      if alpha_code == 6 alpha = 0;
			      else if alpha_code == 7 alpha = 255;
			      else alpha = ((6 - alpha_code) * alpha0 + (alpha_code - 1) * alpha1) / 5;
			  }
			case 3;
			  image.pixels[px_index] = (r0 + 2 * r1) / 3;
			  image.pixels[px_index + 1] = (g0 + 2 * g1) / 3;
			  image.pixels[px_index + 2] = (b0 + 2 * b1) / 3;
			  if alpha0 > alpha1 alpha = ((8 - alpha_code) * alpha0 + (alpha_code - 1) * alpha1) / 7;
			  else {
			      if alpha_code == 6 alpha = 0;
			      else if alpha_code == 7 alpha = 255;
			      else alpha = ((6 - alpha_code) * alpha0 + (alpha_code - 1) * alpha1) / 5;
			  }
		    }
		    
                    dds_image.bdata[px_index + 3] = alpha;
		}
	    }
	}
    }
}

#import "Basic";
#import "File";
#import "d3d12";
#import "dxgi";

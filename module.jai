//  -----
// | DDS |
//  -----

// STRUCTS ----------------------------------------------------

DDS_Image :: struct {
    dwMagic  : u32;
    header   : DDS_HEADER;
    header10 : DDS_HEADER_DXT10;
    bdata    : *u8;
    bdata2   : *u8;
}

NULL_DDS :: DDS_Image.{dwMagic=0};

DDS_HEADER :: struct {
    dwSize              : u32;
    dwFlags             : DDS_HEADER_FLAGS;
    dwHeight            : u32;
    dwWidth             : u32;
    dwPitchOrLinearSize : u32;
    dwDepth             : u32;
    dwMipMapCount       : u32;
    dwReserved1         : [11] u32;
    ddspf               : DDS_PIXELFORMAT;
    dwCaps              : DDS_HEADER_CAPS;
    dwCaps2             : DDS_HEADER_CAPS2;
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
    dwFlags       : DDS_PIXELFORMAT_FLAGS;
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
memcpy_eat :: (pdst: *void, psrc: *void, size: s64) #expand {
    memcpy(pdst, psrc, size);
    `cursor += size;
}

/*
====================
dds_from_file

Convenience, read_entire_file() then dds_from_memory().
====================
*/
dds_from_file :: (path: string) -> DDS_Image {
    bytecode := read_entire_file(path);
    return dds_from_memory(bytecode.data, xx bytecode.count);
}

dds_from_memory :: (data: *u8, length: u64) -> DDS_Image {

    // Check magic for valid dds
    cursor := data;
    magic: u32;
    memcpy_eat(*magic, cursor, size_of(u32));
    if magic != 0x20534444 {
	print("[DDS] Bad magic, returning null!\n");
	return NULL_DDS;
    }

    dds_image: DDS_Image;
    memcpy_eat(*dds_image.header, cursor, size_of(DDS_HEADER));

    // TODO: check validity of header? might be unneccessary
    // Check if header10
    if (dds_image.header.ddspf.dwFlags & .DDPF_FOURCC) &&
	dds_image.header.ddspf.dwFourCC == xx "DX10" {
        memcpy_eat(*dds_image.header10, cursor, size_of(DDS_HEADER_DXT10));
    }

    dds_image.bdata = xx cursor;

    return dds_image;
}

#import "Basic";
#import "File";
#import "d3d12";
#import "dxgi";

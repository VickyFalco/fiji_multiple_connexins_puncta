// ============================================================
// Connexin Puncta Quantification Macro (Fiji / ImageJ)
// Version: 1.0
// Author: Victoria Falco
//
// Description:
// Automated quantification of connexin puncta (Cx43, Cx26)
// within reporter-positive regions, and nuclear counts.
//
// Requirements:
// - Image must be opened with "Split Channels"
// - Multi-slice stack
//
// Outputs:
// - Puncta counts (Cx43, Cx26)
// - Reporter area
// - Nuclei counts (reporter+ and total)
// ============================================================


// ============================
// 1. LOAD IMAGE
// ============================

Imagen = File.openDialog("Seleccione la imagen");
open(Imagen);

Carpeta = getDirectory("image");
Nombre = getInfo("image.filename");

// ============================
// 2. DEFINE CHANNELS
// ============================

canal_reportero = getNumber("Enter reporter channel number (e.g. tdTomato/RFP)", 1);
canal_Cx43 = getNumber("Enter channel for Cx43", 0);
canal_Cx26 = getNumber("Enter channel for Cx26", 2);
canal_DAPI = getNumber("Enter channel for DAPI", 3);


// ============================
// 3. SAVE METADATA
// ============================

run("Show Info...");
saveAs("txt", Carpeta + Nombre + "_Info");
close("Info for " + Nombre + " - C=" + canal_DAPI);


// ============================
// 4. GENERATE REPORTER MASK
// ============================

selectImage(Nombre + " - C=" + canal_reportero);
run("Gaussian Blur...", "sigma=2 stack");
setAutoThreshold("Otsu dark");
run("Convert to Mask");
run("Fill Holes", "stack");
rename("Reporter");


// ============================
// 5. GENERATE ROIs FROM MASK
// ============================

selectImage("Reporter");
setOption("Stack position", true);

for (n=1; n<=nSlices; n++) {
    setSlice(n);
    run("Create Selection");
    roiManager("add");
}


// ============================================================
// 6. FUNCTIONAL BLOCK: Cx ANALYSIS (REUSABLE)
// ============================================================

// -------- Cx43 --------

selectImage(Nombre + " - C=" + canal_Cx43);

for (n=1; n<=nSlices; n++) {
    setSlice(n);
    roiManager("Select", n-1);
    run("Clear Outside","Slice");
}
rename("Cx43");

// Substack
selectImage("Cx43");
step = getNumber("Slice step (z spacing):", 3);
run("Make Subset...", "slices=1-" + nSlices + "-" + step);
rename("Subset_Cx43");
run("8-bit");

// Puncta count
noise = getNumber("Cx43 noise threshold:", 50);

for (n=1; n<=nSlices; n++) {
    setSlice(n);
    run("Duplicate...");
    rename("temp");

    run("Find Maxima...", "noise=" + noise + " dark output=Point Selection");
    run("Flatten");

    selectWindow("temp");
    run("Find Maxima...", "noise=" + noise + " dark output=List");

    selectWindow("Results");
    print(getInfo("window.contents"));

    close("temp");
    selectWindow("Subset_Cx43");
}

run("Images to Stack");
saveAs("tiff", Carpeta + Nombre + "_Cx43_reporter");
saveAs("Results", Carpeta + Nombre + "_Cx43_counts.txt");
close();


// -------- Cx26 --------

selectImage(Nombre + " - C=" + canal_Cx26);

for (n=1; n<=nSlices; n++) {
    setSlice(n);
    roiManager("Select", n-1);
    run("Clear Outside","Slice");
}
rename("Cx26");

step = getNumber("Slice step (z spacing):", 3);

run("Make Subset...", "slices=1-" + nSlices + "-" + step);
rename("Subset_Cx26");
run("8-bit");

noise = getNumber("Cx26 noise threshold:", 50);

for (n=1; n<=nSlices; n++) {
    setSlice(n);
    run("Duplicate...");
    rename("temp");

    run("Find Maxima...", "noise=" + noise + " dark output=Point Selection");
    run("Flatten");

    selectWindow("temp");
    run("Find Maxima...", "noise=" + noise + " dark output=List");

    selectWindow("Results");
    print(getInfo("window.contents"));

    close("temp");
    selectWindow("Subset_Cx26");
}

run("Images to Stack");
saveAs("tiff", Carpeta + Nombre + "_Cx26_reporter");
saveAs("Results", Carpeta + Nombre + "_Cx26_counts.txt");
close();


// ============================
// 7. REPORTER AREA
// ============================

selectImage("Reporter");

for (n=1; n<=nSlices; n++) {
    setSlice(n);
    roiManager("Select", n-1);
    run("Measure");
}

saveAs("Results", Carpeta + Nombre + "_Reporter_area.txt");

roiManager("Save", Carpeta + Nombre + "_Reporter_ROIs.zip");


// ============================
// 8. CLEANUP
// ============================

run("Close All");
roiManager("reset");
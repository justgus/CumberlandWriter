//
//  BackgroundDownloadHandler.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//

import BackgroundAssets
import ExtensionFoundation
import StoreKit

struct DownloaderExtension: StoreDownloaderExtension {
    func shouldDownload(_ assetPack: AssetPack) -> Bool {
        // Use this method to filter out asset packs that the system would otherwise download automatically. You can also remove this method entirely if you just want to rely on the default download behavior.
        return true
    }
}

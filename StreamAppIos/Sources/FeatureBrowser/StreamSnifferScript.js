/**
 * StreamSnifferScript.js
 * Injected vào WKWebView tại .atDocumentStart để hook toàn bộ network & video requests
 */
(function () {
    'use strict';

    if (window.__streamSnifferInjected) return;
    window.__streamSnifferInjected = true;

    // Pattern nhận diện các định dạng video live stream & media
    var HLS_REGEX = /\.m3u8(\?.*)?$/i;
    var DASH_REGEX = /\.mpd(\?.*)?$/i;
    var MP4_REGEX = /\.(mp4|ts|m4v)(\?.*)?$/i;
    var RTMP_REGEX = /^rtmp:\/\//i;

    var reportedURLs = new Set();

    function reportStream(url, mimeType, elementHint) {
        if (!url || typeof url !== 'string') return;
        
        try {
            url = new URL(url, window.location.href).href;
        } catch (e) {
            return;
        }

        if (reportedURLs.has(url)) return;

        var streamType = null;
        if (HLS_REGEX.test(url) || (mimeType && mimeType.indexOf('mpegurl') !== -1)) {
            streamType = 'HLS (.m3u8)';
        } else if (DASH_REGEX.test(url) || (mimeType && mimeType.indexOf('dash+xml') !== -1)) {
            streamType = 'DASH (.mpd)';
        } else if (RTMP_REGEX.test(url)) {
            streamType = 'RTMP';
        } else if (MP4_REGEX.test(url) || (mimeType && mimeType.indexOf('video/mp4') !== -1)) {
            streamType = 'Direct (.mp4/.ts)';
        }

        if (streamType) {
            reportedURLs.add(url);

            var payload = {
                url: url,
                streamType: streamType,
                title: document.title || 'Live Stream',
                mimeType: mimeType || '',
                pageURL: window.location.href,
                elementHint: elementHint || ''
            };

            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.streamSniffer) {
                window.webkit.messageHandlers.streamSniffer.postMessage(payload);
            }
        }
    }

    // 1. Hook window.fetch
    var originalFetch = window.fetch;
    if (originalFetch) {
        window.fetch = function () {
            var args = arguments;
            var resource = args[0];
            var url = (typeof resource === 'string') ? resource : (resource ? resource.url : '');
            
            if (url) {
                reportStream(url, null, 'fetch');
            }

            return originalFetch.apply(this, args).then(function (response) {
                if (response && response.url) {
                    var contentType = response.headers ? response.headers.get('content-type') : null;
                    reportStream(response.url, contentType, 'fetchResponse');
                }
                return response;
            });
        };
    }

    // 2. Hook XMLHttpRequest
    var originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (method, url) {
        if (url) {
            this._sniffedUrl = url;
            reportStream(url, null, 'xhr');
        }
        return originalOpen.apply(this, arguments);
    };

    var originalSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.send = function () {
        var xhr = this;
        xhr.addEventListener('load', function () {
            var contentType = xhr.getResponseHeader('Content-Type');
            reportStream(xhr._sniffedUrl || xhr.responseURL, contentType, 'xhrResponse');
        });
        return originalSend.apply(this, arguments);
    };

    // 3. Quan sát HTMLMediaElement (<video>)
    function inspectMediaElement(video) {
        if (!video) return;
        if (video.src) {
            reportStream(video.src, video.type, 'videoSrc');
        }
        if (video.currentSrc) {
            reportStream(video.currentSrc, null, 'videoCurrentSrc');
        }
        var sources = video.getElementsByTagName('source');
        for (var i = 0; i < sources.length; i++) {
            if (sources[i].src) {
                reportStream(sources[i].src, sources[i].type, 'sourceElement');
            }
        }
    }

    document.addEventListener('play', function (e) {
        if (e.target && e.target.tagName === 'VIDEO') {
            inspectMediaElement(e.target);
        }
    }, true);

    document.addEventListener('loadstart', function (e) {
        if (e.target && e.target.tagName === 'VIDEO') {
            inspectMediaElement(e.target);
        }
    }, true);

    var observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            for (var i = 0; i < mutation.addedNodes.length; i++) {
                var node = mutation.addedNodes[i];
                if (node.tagName === 'VIDEO') {
                    inspectMediaElement(node);
                } else if (node.querySelectorAll) {
                    var videos = node.querySelectorAll('video');
                    for (var j = 0; j < videos.length; j++) {
                        inspectMediaElement(videos[j]);
                    }
                }
            }
        });
    });

    if (document.documentElement) {
        observer.observe(document.documentElement, { childList: true, subtree: true });
    } else {
        document.addEventListener('DOMContentLoaded', function () {
            observer.observe(document.documentElement, { childList: true, subtree: true });
        });
    }
})();
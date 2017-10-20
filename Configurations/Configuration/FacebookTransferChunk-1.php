<?php
/**
 * Copyright 2017 Facebook, Inc.
 *
 * You are hereby granted a non-exclusive, worldwide, royalty-free license to
 * use, copy, modify, and distribute this software in source code or binary
 * form for use in connection with the web services and APIs provided by
 * Facebook.
 *
 * As with any software that integrates with the Facebook platform, your use
 * of this software is subject to the Facebook Developer Principles and
 * Policies [http://developers.facebook.com/policy/]. This copyright notice
 * shall be included in all copies or substantial portions of the software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 */
namespace Facebook\FileUpload;

/**
 * Class FacebookTransferChunk
 *
 * @package Facebook
 */
class FacebookTransferChunk
{
    /**
     * @var FacebookFile The file to chunk during upload.
     */
    private $file;

    /**
     * @var int The ID of the upload session.
     */
    private $uploadSessionId;

    /**
     * @var int Start byte position of the next file chunk.
     */
    private $startOffset;

    /**
     * @var int End byte position of the next file chunk.
     */
    private $endOffset;

    /**
     * @var int The ID of the video.
     */
    private $videoId;

    /**
     * @param FacebookFile $file
     * @param int $uploadSessionId
     * @param int $videoId
     * @param int $startOffset
     * @param int $endOffset
     */
    public function __construct(FacebookFile $file, $uploadSessionId, $videoId, $startOffset, $endOffset)
    {
        $this->file = $file;
        $this->uploadSessionId = $uploadSessionId;
        $this->videoId = $videoId;
        $this->startOffset = $startOffset;
        $this->endOffset = $endOffset;
    }

    /**
     * Return the file entity.
     *
     * @return FacebookFile
     */
    public function getFile()
    {
        return $this->file;
    }

    /**
     * Return a FacebookFile entity with partial content.
     *
     * @return FacebookFile
     */
    public function getPartialFile()
    {
        $maxLength = $this->endOffset - $this->startOffset;

        return new FacebookFile($this->file->getFilePath(), $maxLength, $this->startOffset);
    }

    /**
     * Return upload session Id
     *
     * @return int
     */
    public function getUploadSessionId()
    {
        return $this->uploadSessionId;
    }

    /**
     * Check whether is the last chunk
     *
     * @return bool
     */
    public function isLastChunk()
    {
        return $this->startOffset === $this->endOffset;
    }

    /**
     * @return int
     */
    public function getStartOffset()
    {
        return $this->startOffset;
    }

    /**
     * Get uploaded video Id
     *
     * @return int
     */
    public function getVideoId()
    {
        return $this->videoId;
    }
}

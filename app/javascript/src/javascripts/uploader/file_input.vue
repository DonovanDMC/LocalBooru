<template>
  <span
    class="uploader-file-input"
    :file-enabled="!disableFileUpload"
    :link-enabled="!disableURLUpload"
  >
    <div class="fileinput-wrapper" v-if="!disableFileUpload">
      <label
        class="fileinput"
        for="file-input"
        @dragover="fileDragover"
        @dragleave="fileDragleave"
        @drop="fileDrop"
        :dragging="uploader.dragging"
      >
        <input
          type="file"
          ref="post_file"
          id="file-input"
          accept="image/png,image/apng,image/jpeg,image/gif,image/webp,video/webm,video/mp4,.png,.apng,.jpg,.jpeg,.gif,.webp,.webm,.mp4"
          @change="updatePreviewFile"
          :disabled="disableFileUpload"
        />
        <span class="title">
          <div v-if="uploader.dragging">Release to drop a file here</div>
          <div v-else>Choose an image or video to upload</div>
        </span>
        <span class="subtitle">
          <div v-if="disableURLUpload">
            {{ this.getFileURL().name }}
          </div>
          <div v-else><u>Browse for file</u> or drag and drop</div>
        </span>
      </label>
      <button
        class="btn-clear"
        @click.prevent="clearFileUpload"
        v-show="disableURLUpload"
      >Clear</button>
    </div>

    <div class="linkinput-wrapper" v-if="!disableURLUpload">
      <div class="box-section background-red" v-if="badDirectURL">
        The direct URL entered has the following problem: {{ directURLProblem }}<br>
        You should review <a href="/wiki_pages/howto:sites_and_sources">the sourcing guide</a>.
      </div>
      <label class="linkinput">
        <span class="linkinput-or">{{ !disableFileUpload ? "OR" : "URL" }}</span>
        <input
          type="text"
          size="50"
          placeholder="Paste image URL"
          v-model="uploadURL"
          :disabled="disableURLUpload"
        />
      </label>
    </div>
  </span>
</template>

<script>
export default {
  data() {
    return {
      uploader: {
        dragging: false,
      },
      uploadURL: new URLSearchParams(window.location.search).get("upload_url") || "",
      exceededFileSize: 0,
      disableFileUpload: false,
      disableURLUpload: false,
    }
  },
  computed: {
    directURLProblem: function () {
      return this.directURLCheck(this.uploadURL);
    },
    badDirectURL: function () {
      return !!this.directURLProblem;
    },
    invalidUploadValue: function () {
      return this.badDirectURL;
    }
  },
  watch: {
    uploadURL: {
      immediate: true,
      handler() {
        this.uploadValueChanged(this.uploadURL);
        this.updatePreviewURL();
        if (this.uploadURL.length === 0)
          this.setEmptyThumb();
      }
    },
    invalidUploadValue() {
      this.$emit("invalidUploadValueChanged", this.invalidUploadValue);
    }
  },
  methods: {
    fileDragover(event) {
      event.preventDefault();
      this.uploader.dragging = true;
    },
    fileDragleave(event) {
      event.preventDefault();
      this.uploader.dragging = false;
    },
    fileDrop(event) {
      event.preventDefault();
      this.uploader.dragging = false;

      this.$refs.post_file.files = event.dataTransfer.files;
      this.updatePreviewFile();
    },
    directURLCheck(url) {
      const patterns = [
        {reason: "Thumbnail URL", test: /[at]\.(facdn|furaffinity)\.net/gi},
        {reason: "Sample URL", test: /pximg\.net.*\/img-master\//gi},
        {reason: "Sample URL", test: /d3gz42uwgl1r1y\.cloudfront\.net\/.*\/\d+x\d+\./gi},
        {reason: "Sample URL", test: /pbs\.twimg\.com\/media\/[\w\-_]+\.(jpg|png)(:large)?$/gi},
        {reason: "Sample URL", test: /pbs\.twimg\.com\/media\/[\w\-_]+\?format=(jpg|png)(?!&name=orig)/gi},
        {reason: "Sample URL", test: /derpicdn\.net\/.*\/large\./gi},
        {reason: "Sample URL", test: /metapix\.net\/files\/(preview|screen)\//gi},
        {reason: "Sample URL", test: /sofurryfiles\.com\/std\/preview/gi}
      ];
      for (const pattern of patterns) {
        if (pattern.test.test(url)) {
          return pattern.reason;
        }
      }
      return "";
    },
    clearFileUpload() {
      if (!this.$refs["post_file"]?.files?.[0]) {
        return;
      }
      this.$refs["post_file"].value = null;
      this.disableURLUpload = false;
      this.disableFileUpload = false;
      this.exceededFileSize = 0;
      this.setEmptyThumb();
      this.uploadValueChanged("");

    },
    updatePreviewURL() {
      if (this.uploadURL.length === 0 || this.$refs["post_file"]?.files?.[0]) {
        this.disableFileUpload = false;
        return;
      }
      this.disableFileUpload = true;
      const domain = $("<a>").prop("href", this.uploadURL).prop("hostname");

      if (/^(https?\:\/\/|www).*?$/.test(this.uploadURL)) {
        const isVideo = /^(https?\:\/\/|www).*?\.(webm)$/.test(this.uploadURL);
        this.previewChanged(this.uploadURL, isVideo);
      } else {
        this.setEmptyThumb();
      }
    },
    getFileURL() {
      return this.$refs["post_file"].files[0];
    },
    updatePreviewFile() {
      const file = this.getFileURL();
      const objectUrl = URL.createObjectURL(file);
      this.disableURLUpload = true;
      this.uploadValueChanged(file);
      this.previewChanged(objectUrl, file.type === "video/webm");
    },
    uploadValueChanged(value) {
      this.$emit("uploadValueChanged", value);
    },
    setEmptyThumb() {
      this.previewChanged("", false);
    },
    previewChanged(url, isVideo) {
      this.$emit("previewChanged", {url: url, isVideo: isVideo});
    },
  }
}
</script>

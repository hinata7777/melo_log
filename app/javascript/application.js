// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

document.addEventListener('click', function (event) {
  if (!event.target.classList.contains('select-song')) return;

  // クリックしたボタンからデータ取得
  const spotifyId = event.target.dataset.spotifyId;
  const title = event.target.dataset.title;
  const artist = event.target.dataset.artist;
  const albumArtUrl = event.target.dataset.albumArtUrl;
  const spotifyUrl = event.target.dataset.spotifyUrl;

  // hidden_fieldにセット
  document.querySelector('input[name="spotify_id"]').value = spotifyId;
  document.querySelector('input[name="title"]').value = title;
  document.querySelector('input[name="artist"]').value = artist;
  document.querySelector('input[name="album_art_url"]').value = albumArtUrl;
  document.querySelector('input[name="spotify_url"]').value = spotifyUrl;

  // 未選択メッセージを非表示にする
  document.getElementById('no-selection').classList.add('hidden');

  // プレビュー部分を表示に切り替え
  const preview = document.getElementById('song-preview');
  preview.classList.remove('hidden');

  // プレビュー更新
  document.getElementById('preview-art').src = albumArtUrl;
  document.getElementById('preview-title').textContent = title;
  document.getElementById('preview-artist').textContent = artist;
});
# sample_rails_url

save url as model uniquely

## Usage

```ruby
url = Url.parse("https://sample.com/sample?test=value#test")
url # <Url:0x00000002787268 id: 1, scheme: "https", host: "sample.com", port: 0, path: "/sample", query: "test=value", fragment: "test", path_component_hash: "3ecfe79d5397c210297c17d14b97f866", hash_number: 0>
url.to_s # "https://sample.com/sample?test=value#test"
```

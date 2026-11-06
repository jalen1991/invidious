require "../../parsers_helper.cr"

Spectator.describe "parse_related_video" do
  it "extracts the channel of a single-creator video" do
    related = JSON.parse(<<-JSON)
      {
        "videoId": "single-creator-id",
        "title": {"simpleText": "Single creator video"},
        "shortBylineText": {
          "runs": [{
            "text": "Single Channel",
            "navigationEndpoint": {
              "browseEndpoint": {"browseId": "UC-single"}
            }
          }]
        }
      }
      JSON

    video = Invidious::Videos::Parser.parse_related_video(related).not_nil!

    expect(video["author"].as_s).to eq("Single Channel")
    expect(video["ucid"].as_s).to eq("UC-single")
  end

  it "links a multi-creator video to its first collaborator" do
    related = JSON.parse(<<-JSON)
      {
        "videoId": "collaboration-id",
        "title": {"simpleText": "Collaboration video"},
        "shortBylineText": {
          "runs": [{
            "text": "First Channel and Second Channel",
            "navigationEndpoint": {
              "showDialogCommand": {
                "panelLoadingStrategy": {
                  "inlineContent": {
                    "dialogViewModel": {
                      "customContent": {
                        "listViewModel": {
                          "listItems": [
                            {
                              "listItemViewModel": {
                                "rendererContext": {
                                  "commandContext": {
                                    "onTap": {
                                      "innertubeCommand": {
                                        "browseEndpoint": {"browseId": "UC-first"}
                                      }
                                    }
                                  }
                                }
                              }
                            },
                            {
                              "listItemViewModel": {
                                "rendererContext": {
                                  "commandContext": {
                                    "onTap": {
                                      "innertubeCommand": {
                                        "browseEndpoint": {"browseId": "UC-second"}
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          ]
                        }
                      }
                    }
                  }
                }
              }
            }
          }]
        }
      }
      JSON

    video = Invidious::Videos::Parser.parse_related_video(related).not_nil!

    # The combined label is kept as the author, but the card links to the
    # first collaborator's channel.
    expect(video["author"].as_s).to eq("First Channel and Second Channel")
    expect(video["ucid"].as_s).to eq("UC-first")
  end

  it "skips collaborators that have no channel destination" do
    related = JSON.parse(<<-JSON)
      {
        "videoId": "collaboration-id",
        "title": {"simpleText": "Collaboration video"},
        "shortBylineText": {
          "runs": [{
            "text": "First Channel and Second Channel",
            "navigationEndpoint": {
              "showDialogCommand": {
                "panelLoadingStrategy": {
                  "inlineContent": {
                    "dialogViewModel": {
                      "customContent": {
                        "listViewModel": {
                          "listItems": [
                            {"listItemViewModel": {"title": {"content": "First Channel"}}},
                            {
                              "listItemViewModel": {
                                "rendererContext": {
                                  "commandContext": {
                                    "onTap": {
                                      "innertubeCommand": {
                                        "browseEndpoint": {"browseId": "UC-second"}
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          ]
                        }
                      }
                    }
                  }
                }
              }
            }
          }]
        }
      }
      JSON

    video = Invidious::Videos::Parser.parse_related_video(related).not_nil!

    expect(video["ucid"].as_s).to eq("UC-second")
  end

  it "keeps the channel id empty when there is no channel destination" do
    related = JSON.parse(<<-JSON)
      {
        "videoId": "unlinked-id",
        "title": {"simpleText": "Unlinked video"},
        "shortBylineText": {"runs": [{"text": "Unlinked author"}]}
      }
      JSON

    video = Invidious::Videos::Parser.parse_related_video(related).not_nil!

    expect(video["author"].as_s).to eq("Unlinked author")
    expect(video["ucid"].as_s).to be_empty
  end
end

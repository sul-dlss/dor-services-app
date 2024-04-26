# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::DescriptiveMetadataIndexer do
  subject(:indexer) { described_class.new(cocina:) }

  let(:bare_druid) { 'qy781dy0220' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:doc) { indexer.to_solr }
  let(:cocina) do
    build(:dro, id: druid).new(
      description: description.merge(purl: "https://purl.stanford.edu/#{bare_druid}")
    )
  end

  describe 'publisher mappings from Cocina to Solr originInfo_publisher_tesim' do
    # Construct publisher from selected event
    context 'when one publisher' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects publisher' do
        expect(doc).to include('originInfo_publisher_tesim' => 'Stanford University Press')
      end
    end

    context 'when multiple publishers, one primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ]
                },
                {
                  name: [
                    {
                      value: 'Highwire Press'
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ],
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end

      it 'selects primary publisher' do
        expect(doc).to include('originInfo_publisher_tesim' => 'Highwire Press')
      end
    end

    context 'when multiple publishers, none primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ]
                },
                {
                  name: [
                    {
                      value: 'Highwire Press'
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'concatenates publishers with space colon space' do
        expect(doc).to include('originInfo_publisher_tesim' => 'Stanford University Press : Highwire Press')
      end
    end

    context 'when no event contributor with publisher role' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  role: [
                    {
                      value: 'issuing body'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'does not select a publisher' do
        expect(doc).not_to include('originInfo_publisher_tesim')
      end
    end

    context 'when publisher role capitalized' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  role: [
                    {
                      value: 'Publisher'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects publisher' do
        expect(doc).to include('originInfo_publisher_tesim' => 'Stanford University Press')
      end
    end

    context 'when publication event with roleless contributor' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'does not select a publisher' do
        expect(doc).not_to include('originInfo_publisher_tesim')
      end
    end

    context 'when non-publication event with publisher role' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              type: 'production',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects publisher' do
        expect(doc).to include('originInfo_publisher_tesim' => 'Stanford University Press')
      end
    end

    context 'when parallelEvent' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              parallelEvent: [
                {
                  contributor: [
                    {
                      name: [
                        {
                          value: 'СФУ',
                          valueLanguage: {
                            code: 'rus',
                            source: {
                              code: 'iso639-2b'
                            },
                            valueScript: {
                              code: 'Cyrl',
                              source: {
                                code: 'iso15924'
                              }
                            }
                          }
                        }
                      ],
                      role: [
                        {
                          value: 'publisher'
                        }
                      ],
                      status: 'primary'
                    }
                  ],
                  date: [
                    {
                      value: '1990'
                    }
                  ]
                },
                {
                  contributor: [
                    {
                      name: [
                        {
                          value: 'SFU',
                          valueLanguage: {
                            code: 'eng',
                            source: {
                              code: 'iso639-2b'
                            },
                            valueScript: {
                              code: 'Latn',
                              source: {
                                code: 'iso15924'
                              }
                            }
                          }
                        }
                      ],
                      role: [
                        {
                          value: 'publisher'
                        }
                      ]
                    }
                  ],
                  date: [
                    {
                      value: '1990'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects publisher from preferred event' do
        expect(doc).to include('originInfo_publisher_tesim' => 'СФУ')
      end
    end

    context 'when parallelValue, one primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      parallelValue: [
                        {
                          value: 'СФУ',
                          valueLanguage: {
                            code: 'rus',
                            source: {
                              code: 'iso639-2b'
                            },
                            valueScript: {
                              code: 'Cyrl',
                              source: {
                                code: 'iso15924'
                              }
                            }
                          }
                        },
                        {
                          value: 'SFU',
                          valueLanguage: {
                            code: 'eng',
                            source: {
                              code: 'iso639-2b'
                            },
                            valueScript: {
                              code: 'Latn',
                              source: {
                                code: 'iso15924'
                              }
                            }
                          },
                          status: 'primary'
                        }
                      ]
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects primary publisher' do
        expect(doc).to include('originInfo_publisher_tesim' => 'SFU')
      end
    end

    context 'when parallelValue, none primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      parallelValue: [
                        {
                          value: 'СФУ',
                          valueLanguage: {
                            code: 'rus',
                            source: {
                              code: 'iso639-2b'
                            },
                            valueScript: {
                              code: 'Cyrl',
                              source: {
                                code: 'iso15924'
                              }
                            }
                          }
                        },
                        {
                          value: 'SFU',
                          valueLanguage: {
                            code: 'eng',
                            source: {
                              code: 'iso639-2b'
                            },
                            valueScript: {
                              code: 'Latn',
                              source: {
                                code: 'iso15924'
                              }
                            }
                          }
                        }
                      ]
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'concatenates publishers with space colon space' do
        expect(doc).to include('originInfo_publisher_tesim' => 'СФУ : SFU')
      end
    end

    context 'when structuredValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      structuredValue: [
                        {
                          value: 'Stanford University Press'
                        },
                        {
                          value: 'Internal Division'
                        }
                      ]
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'concatenates values with period space' do
        expect(doc).to include('originInfo_publisher_tesim' => 'Stanford University Press. Internal Division')
      end
    end

    context 'when structuredValue in parallelEvent' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              parallelEvent: [
                {
                  contributor: [
                    {
                      name: [
                        {
                          structuredValue: [
                            {
                              value: 'Stanford University Press'
                            },
                            {
                              value: 'Internal Division'
                            }
                          ]
                        }
                      ],
                      role: [
                        {
                          value: 'publisher'
                        }
                      ]
                    }
                  ]
                },
                {
                  contributor: [
                    {
                      name: [
                        {
                          structuredValue: [
                            {
                              value: 'Another'
                            },
                            {
                              value: 'Value'
                            }
                          ]
                        }
                      ],
                      role: [
                        {
                          value: 'publisher'
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'concatenates preferred values with period space' do
        expect(doc).to include('originInfo_publisher_tesim' => 'Stanford University Press. Internal Division')
      end
    end

    context 'when structuredValue in parallelValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      parallelValue: [
                        {
                          structuredValue: [
                            {
                              value: 'Stanford University Press'
                            },
                            {
                              value: 'Internal Division'
                            }
                          ],
                          status: 'primary'
                        },
                        {
                          structuredValue: [
                            {
                              value: 'Another'
                            },
                            {
                              value: 'Value'
                            }
                          ]
                        }
                      ]
                    }
                  ],
                  role: [
                    {
                      value: 'publisher'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'concatenates preferred values with period space' do
        expect(doc).to include('originInfo_publisher_tesim' => 'Stanford University Press. Internal Division')
      end
    end
  end
end

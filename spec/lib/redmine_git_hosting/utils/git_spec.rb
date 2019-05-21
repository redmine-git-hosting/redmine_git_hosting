require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe RedmineGitHosting::Utils::Git do
  include RedmineGitHosting::Utils::Git

  describe '.parse_refspec' do
    context 'it should accept different refspec format' do
      it 'should accept <name>' do
        expect(parse_refspec('dev')).to eq ({ type: nil, name: 'dev' })
      end

      it 'should accept a branch path' do
        expect(parse_refspec('refs/branches/dev')).to eq ({ type: 'branches', name: 'dev' })
      end

      it 'should accept the wildcard param (*)' do
        expect(parse_refspec('refs/branches/dev/*')).to eq ({ type: 'branches', name: 'dev/*' })
        expect(parse_refspec('refs/tags/*')).to eq ({ type: 'tags', name: '*' })
      end

      it 'should parse different refspec path' do
        expect(parse_refspec('refs/remotes/origin/experiment/*')).to eq ({ type: 'remotes', name: 'origin/experiment/*' })
        expect(parse_refspec('refs/remotes/origin/experiment/master')).to eq ({ type: 'remotes', name: 'origin/experiment/master' })
        expect(parse_refspec('refs/remotes/origin/experiment')).to eq ({ type: 'remotes', name: 'origin/experiment' })
        expect(parse_refspec('refs/heads/experiment')).to eq ({ type: 'heads', name: 'experiment' })
      end
    end
  end
end

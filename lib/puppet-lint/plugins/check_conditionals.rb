class PuppetLint::Plugins::CheckConditionals < PuppetLint::CheckPlugin
  # Public: Test the manifest tokens for any selectors embedded within resource
  # declarations and record a warning for each instance found.
  #
  # Returns nothing.
  check 'selector_inside_resource' do
    resource_indexes.each do |resource|
      resource_tokens = tokens[resource[:start]..resource[:end]].reject { |r|
        [:COMMENT, :MLCOMMENT, :WHITESPACE, :INDENT].include? r.type
      }

      resource_tokens.each_index do |resource_token_idx|
        if resource_tokens[resource_token_idx].type == :FARROW
          if resource_tokens[resource_token_idx + 1].type == :VARIABLE
            unless resource_tokens[resource_token_idx + 2].nil?
              if resource_tokens[resource_token_idx + 2].type == :QMARK
                notify :warning, {
                  :message    => 'selector inside resource block',
                  :linenumber => resource_tokens[resource_token_idx].line,
                  :column     => resource_tokens[resource_token_idx].column,
                }
              end
            end
          end
        end
      end
    end
  end

  check 'case_without_default' do
    case_indexes = []

    tokens.each_index do |token_idx|
      if tokens[token_idx].type == :CASE
        depth = 0
        tokens[(token_idx + 1)..-1].each_index do |case_token_idx|
          idx = case_token_idx + token_idx + 1
          if tokens[idx].type == :LBRACE
            depth += 1
          elsif tokens[idx].type == :RBRACE
            depth -= 1
            if depth == 0
              case_indexes << {:start => token_idx, :end => idx}
              break
            end
          end
        end
      end
    end

    case_indexes.each do |kase|
      case_tokens = tokens[kase[:start]..kase[:end]]

      unless case_tokens.index { |r| r.type == :DEFAULT }
        notify :warning, {
          :message    => 'case statement without a default case',
          :linenumber => case_tokens.first.line,
          :column     => case_tokens.first.column,
        }
      end
    end
  end
end

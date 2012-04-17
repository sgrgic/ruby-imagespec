class ImageSpec

  module Parser

    class JPEG

      CONTENT_TYPE = 'image/jpeg'

      def self.attributes(stream)
        width, height = dimensions(stream)
        {:width => width, :height => height, :content_type => CONTENT_TYPE}
      end

      def self.detected?(stream)
        stream.rewind
        case stream.read(10)
          when /^\xff\xd8\xff\xe0\x00\x10JFIF/ then true
          when /^\xff\xd8\xff\xe1(.*){2}Exif/  then true
          else false
        end
      end

      def self.dimensions(stream)
        stream.rewind
        raise 'malformed JPEG' unless stream.getc.ord == 0xFF && stream.getc.ord == 0xD8 # SOI

        class << stream
          def readint
            (readchar.ord << 8) + readchar.ord
          end

          def readframe
            read(readint - 2)
          end

          def readsof
            [readint, readchar.ord, readint, readint, readchar.ord]
          end

          def next
            c = readchar.ord while c != 0xFF
            c = readchar.ord while c == 0xFF
            c
          end
        end

        while marker = stream.next
          case marker
          when 0xC0..0xC3, 0xC5..0xC7, 0xC9..0xCB, 0xCD..0xCF
            length, bits, height, width, components = stream.readsof
            raise 'malformed JPEG' unless length == 8 + components * 3
            return [width, height]
          when 0xD9, 0xDA
            break
          when 0xFE
            @comment = stream.readframe
          when 0xE1
            stream.readframe
          else
            stream.readframe
          end
        end
      end

    end

  end

end

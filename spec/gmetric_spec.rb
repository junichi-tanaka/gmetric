require "helper"

describe Ganglia::GMetric do

  describe Ganglia::XDRPacket do
    def hex(data)
      [data].pack("H")
    end

    it "should pack an int & uint into XDR format" do
      xdr = Ganglia::XDRPacket.new
      xdr.pack_int(1)
      expect(xdr.data).to eq "\000\000\000\001"

      xdr = Ganglia::XDRPacket.new
      xdr.pack_uint(8)
      expect(xdr.data).to eq "\000\000\000\b"
    end

    it "should pack string" do
      xdr = Ganglia::XDRPacket.new
      xdr.pack_string("test")
      expect(xdr.data).to eq "\000\000\000\004test"
    end
  end

  it "should pack GMetric into XDR format from Ruby hash" do
    data = {
      :group => '',
      :slope => 'both',
      :name => 'foo',
      :value => 'bar',
      :tmax => 60,
      :units => '',
      :dmax => 0,
      :type => 'string'
    }

    g = Ganglia::GMetric.pack(data)
    expect(g.size).to eq 2
    expect(g[0]).to eq "\000\000\000\200\000\000\000\000\000\000\000\003foo\000\000\000\000\000\000\000\000\006string\000\000\000\000\000\003foo\000\000\000\000\000\000\000\000\003\000\000\000<\000\000\000\000\000\000\000\001\000\000\000\005GROUP\000\000\000\000\000\000\000"
    expect(g[1]).to eq "\000\000\000\205\000\000\000\000\000\000\000\003foo\000\000\000\000\000\000\000\000\002%s\000\000\000\000\000\003bar\000"
  end

  it "should raise an error on missing name, value, type" do
    %w(name value type).each do |key|
      expect {
        data = {:name => 'a', :type => 'b', :value => 'c'}
        data.delete key.to_sym
        Ganglia::GMetric.pack(data)
      }.to raise_error
    end
  end

  it "should verify type and raise error on invalid type" do
    %w(string int8 uint8 int16 uint16 int32 uint32 float double).each do |type|
      expect {
        data = {:name => 'a', :type => type, :value => 'c'}
        Ganglia::GMetric.pack(data)
      }.not_to raise_error
    end

    expect {
      data = {:name => 'a', :type => 'int', :value => 'c'}
      Ganglia::GMetric.pack(data)
    }.to raise_error
  end

  it "should allow host spoofing" do
    expect {
      data = {:name => 'a', :type => 'uint8', :value => 'c', :spoof => 1, :host => 'host'}
      Ganglia::GMetric.pack(data)

      data = {:name => 'a', :type => 'uint8', :value => 'c', :spoof => true, :host => 'host'}
      Ganglia::GMetric.pack(data)
    }.not_to raise_error

  end

  it "should allow group meta data" do
    expect {
      data = {:name => 'a', :type => 'uint8', :value => 'c', :spoof => 1, :host => 'host', :group => 'test'}
      g = Ganglia::GMetric.pack(data)
      expect(g[0]).to eq "\000\000\000\200\000\000\000\000\000\000\000\001a\000\000\000\000\000\000\001\000\000\000\005uint8\000\000\000\000\000\000\001a\000\000\000\000\000\000\000\000\000\000\003\000\000\000<\000\000\000\000\000\000\000\001\000\000\000\005GROUP\000\000\000\000\000\000\004test"

    }.not_to raise_error
  end

  it "should deny group meta data" do
    expect {
      data = {:name => 'a', :type => 'uint8', :value => 'c', :spoof => 1, :host => 'host'}
      g = Ganglia::GMetric.pack(data)
      expect(g[0]).to eq "\000\000\000\200\000\000\000\000\000\000\000\001a\000\000\000\000\000\000\001\000\000\000\005uint8\000\000\000\000\000\000\001a\000\000\000\000\000\000\000\000\000\000\003\000\000\000<\000\000\000\000\000\000\000\000"

    }.not_to raise_error
  end

  it "should use EM reactor if used within event loop" do
    skip 'stub out connection class'

    require 'eventmachine'
    EventMachine.run do
      Ganglia::GMetric.send("127.0.0.1", 1111, {
                              :group => '',
                              :name => 'pageviews',
                              :units => 'req/min',
                              :type => 'uint8',
                              :value => 7000,
                              :tmax => 60,
                              :dmax => 300
      })

      EM.stop
    end
  end
end
